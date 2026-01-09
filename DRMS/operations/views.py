from django.shortcuts import render, get_object_or_404
from django.http import JsonResponse
from django.views.decorators.http import require_http_methods
from django.views.decorators.csrf import csrf_exempt
from django.contrib.auth.decorators import login_required
from django.db.models import Q, Count, Sum
from django.utils import timezone
from datetime import timedelta
import json
# DRF imports for JWT support
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status

from .models import (
    Donation, DonationItem, DonationAcknowledgment,
    HelpRequest, HelpRequestStatusHistory,
    TaskAssignment, TaskAssignmentStatusHistory,
    Transport, TransportTrip
)
from .utils import find_nearby_volunteers, find_nearest_camp_admin, find_nearest_camp, calculate_distance
from relief.models import Resource, ResourceRequest
from disasters.models import Disasters
from shelters.models import Camp
from users.models import User, CampAdmin, Volunteer


# ========================================
# DONATION MANAGEMENT VIEWS
# ========================================

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def list_donations(request):
    """
    List all donations
    - Donors see only their donations
    - Camp admins see donations for their camp
    - Super admins see all donations
    """
    donations = Donation.objects.all()
    
    # If user is donor, show only their donations
    if request.user.role == 'donor':
        donations = donations.filter(created_by=request.user)
    # If user is camp_admin, show only donations for their camp
    elif request.user.role == 'camp_admin':
        try:
            camp_admin = CampAdmin.objects.get(user=request.user)
            donations = donations.filter(camp=camp_admin.camp)
        except CampAdmin.DoesNotExist:
            donations = Donation.objects.none()
    
    donations = donations.order_by('-donation_date')
    
    donation_list = []
    for donation in donations:
        items = donation.items.all()
        donation_list.append({
            'id': donation.id,
            'donor_name': donation.donor_name,
            'donor_type': donation.donor_type,
            'contact_email': donation.contact_email,
            'contact_phone': donation.contact_phone,
            'camp_id': donation.camp.id if donation.camp else None,
            'camp_name': donation.camp.name if donation.camp else None,
            'status': donation.status,
            'donation_date': donation.donation_date.isoformat(),
            'created_by': donation.created_by.username if donation.created_by else None,
            'items': [{
                'id': item.id,
                'resource_name': item.resource.name if item.resource else None,
                'resource_id': item.resource.id if item.resource else None,
                'quantity': float(item.quantity)
            } for item in items],
            'has_acknowledgment': hasattr(donation, 'donationacknowledgment'),
            'acknowledgment': {
                'text': donation.donationacknowledgment.acknowledgment_text,
                'acknowledged_by': donation.donationacknowledgment.acknowledged_by.username if hasattr(donation, 'donationacknowledgment') and donation.donationacknowledgment.acknowledged_by else None,
                'acknowledged_at': donation.donationacknowledgment.acknowledged_at.isoformat() if hasattr(donation, 'donationacknowledgment') else None
            } if hasattr(donation, 'donationacknowledgment') else None
        })
    
    return Response({'donations': donation_list})


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def create_donation(request):
    """
    Create a new donation
    - Donors can create donations for specific camps
    - Donations start as 'pending' and need camp admin approval
    """
    try:
        data = json.loads(request.body)
        
        donor_name = data.get('donor_name')
        donor_type = data.get('donor_type', 'individual')
        camp_id = data.get('camp_id')
        items = data.get('items', [])
        
        if not donor_name or not items:
            return Response({'error': 'donor_name and items are required'}, status=status.HTTP_400_BAD_REQUEST)
        
        if not camp_id:
            return Response({'error': 'camp_id is required. Please specify which camp you want to donate to.'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Validate donor_type
        valid_types = ['individual', 'organization']
        if donor_type not in valid_types:
            return Response({'error': f'Invalid donor_type. Must be one of: {valid_types}'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Get the camp
        camp = get_object_or_404(Camp, id=camp_id)
        
        # If user is donor, use their user info
        if request.user.role == 'donor':
            donor_name = donor_name or request.user.username
            contact_email = data.get('contact_email', '') or request.user.email
            contact_phone = data.get('contact_phone', '') or request.user.phone
        else:
            contact_email = data.get('contact_email', '')
            contact_phone = data.get('contact_phone', '')
        
        donation = Donation.objects.create(
            donor_name=donor_name,
            donor_type=donor_type,
            contact_email=contact_email,
            contact_phone=contact_phone,
            camp=camp,
            status='pending',  # Donations need approval
            created_by=request.user
        )
        
        # Create donation items
        for item_data in items:
            resource_id = item_data.get('resource_id')
            quantity = item_data.get('quantity')
            
            if resource_id and quantity:
                try:
                    resource = Resource.objects.get(id=resource_id)
                    DonationItem.objects.create(
                        donation=donation,
                        resource=resource,
                        quantity=quantity
                    )
                    # Note: Inventory is NOT updated until donation is accepted by camp admin
                except Resource.DoesNotExist:
                    continue
        
        return Response({
            'message': 'Donation created successfully. It is pending approval from the camp admin.',
            'donation_id': donation.id,
            'camp_name': camp.name,
            'status': donation.status,
            'donation_date': donation.donation_date.isoformat()
        }, status=status.HTTP_201_CREATED)
        
    except json.JSONDecodeError:
        return Response({'error': 'Invalid JSON'}, status=status.HTTP_400_BAD_REQUEST)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['PUT', 'PATCH'])
@permission_classes([IsAuthenticated])
def update_donation_status(request, donation_id):
    """
    Update donation status - Accept or Reject (camp admin only for their camp)
    """
    if request.user.role not in ['super_admin', 'camp_admin']:
        return Response({'error': 'Unauthorized. Admin role required.'}, status=status.HTTP_403_FORBIDDEN)
    
    try:
        new_status = request.data.get('status')
        acknowledgment_text = request.data.get('acknowledgment_text', 'Thank you for your donation!')
        
        if not new_status:
            return Response({'error': 'status is required'}, status=status.HTTP_400_BAD_REQUEST)
        
        donation = get_object_or_404(Donation, id=donation_id)
        
        # If camp_admin, ensure they can only manage donations for their camp
        if request.user.role == 'camp_admin':
            try:
                camp_admin = CampAdmin.objects.get(user=request.user)
                if donation.camp != camp_admin.camp:
                    return JsonResponse({
                        'error': 'You can only manage donations for your own camp'
                    }, status=403)
            except CampAdmin.DoesNotExist:
                return JsonResponse({'error': 'Camp admin profile not found'}, status=403)
        
        # Validate status
        valid_statuses = ['pending', 'accepted', 'rejected']
        if new_status not in valid_statuses:
            return JsonResponse({'error': f'Invalid status. Must be one of: {valid_statuses}'}, status=400)
        
        previous_status = donation.status
        donation.status = new_status
        donation.save()
        
        # If accepted, update resource inventory
        if new_status == 'accepted' and previous_status != 'accepted':
            for item in donation.items.all():
                if item.resource:
                    resource = item.resource
                    resource.total_quantity += item.quantity
                    resource.available_quantity += item.quantity
                    resource.save()
                    
                    # Create inventory transaction
                    from relief.models import ResourceInventoryTransaction
                    ResourceInventoryTransaction.objects.create(
                        resource=resource,
                        transaction_type='donation',
                        quantity_delta=item.quantity,
                        reason=f'Donation {donation.id} accepted from {donation.donor_name}',
                        related_donation_item=item,
                        created_by=request.user
                    )
        
        # Create or update acknowledgment
        acknowledgment, created = DonationAcknowledgment.objects.get_or_create(
            donation=donation,
            defaults={
                'acknowledgment_text': acknowledgment_text,
                'acknowledged_by': request.user
            }
        )
        
        if not created:
            acknowledgment.acknowledgment_text = acknowledgment_text
            acknowledgment.acknowledged_by = request.user
            acknowledgment.save()
        
        return Response({
            'message': f'Donation {new_status} successfully',
            'donation_id': donation.id,
            'previous_status': previous_status,
            'new_status': new_status,
            'acknowledgment_id': acknowledgment.id,
            'acknowledged_at': acknowledgment.acknowledged_at.isoformat()
        })
        
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def acknowledge_donation(request, donation_id):
    """
    Acknowledge a donation (admin only) - Legacy method, use update_donation_status instead
    """
    if request.user.role not in ['super_admin', 'camp_admin']:
        return Response({'error': 'Unauthorized. Admin role required.'}, status=status.HTTP_403_FORBIDDEN)
    
    try:
        acknowledgment_text = request.data.get('acknowledgment_text', 'Thank you for your donation!')
        
        donation = get_object_or_404(Donation, id=donation_id)
        
        # If camp_admin, ensure they can only acknowledge donations for their camp
        if request.user.role == 'camp_admin':
            try:
                camp_admin = CampAdmin.objects.get(user=request.user)
                if donation.camp != camp_admin.camp:
                    return Response({
                        'error': 'You can only acknowledge donations for your own camp'
                    }, status=status.HTTP_403_FORBIDDEN)
            except CampAdmin.DoesNotExist:
                return Response({'error': 'Camp admin profile not found'}, status=status.HTTP_403_FORBIDDEN)
        
        acknowledgment, created = DonationAcknowledgment.objects.get_or_create(
            donation=donation,
            defaults={
                'acknowledgment_text': acknowledgment_text,
                'acknowledged_by': request.user
            }
        )
        
        if not created:
            acknowledgment.acknowledgment_text = acknowledgment_text
            acknowledgment.acknowledged_by = request.user
            acknowledgment.save()
        
        return Response({
            'message': 'Donation acknowledged successfully',
            'acknowledgment_id': acknowledgment.id,
            'acknowledged_at': acknowledgment.acknowledged_at.isoformat()
        })
        
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# ========================================
# HELP REQUEST (SOS) MANAGEMENT VIEWS
# ========================================

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def list_help_requests(request):
    """
    List all help requests
    - Victims see only their requests
    - Volunteers see requests assigned to them and nearby requests
    - Admins see all requests
    """
    requests = HelpRequest.objects.all()
    
    # Role-based filtering
    if request.user.role == 'victim':
        requests = requests.filter(victim=request.user)
    elif request.user.role == 'volunteer':
        # Volunteers see assigned requests and nearby pending requests
        assigned_requests = requests.filter(assigned_volunteer=request.user)
        if request.user.latitude and request.user.longitude:
            # Get nearby pending requests within 50km
            nearby_requests = requests.filter(
                status='pending',
                latitude__isnull=False,
                longitude__isnull=False
            )
            nearby_list = []
            for req in nearby_requests:
                distance = calculate_distance(
                    float(request.user.latitude), float(request.user.longitude),
                    float(req.latitude), float(req.longitude)
                ) if req.latitude and req.longitude else None
                if distance and distance <= 50:
                    nearby_list.append(req.id)
            requests = assigned_requests | requests.filter(id__in=nearby_list)
        else:
            requests = assigned_requests
    
    # Filter by status
    status_filter = request.GET.get('status')
    if status_filter:
        requests = requests.filter(status=status_filter)
    
    # Filter by disaster
    disaster_id = request.GET.get('disaster_id')
    if disaster_id:
        requests = requests.filter(disasters_id=disaster_id)
    
    requests = requests.order_by('-requested_at')
    
    request_list = []
    for req in requests:
        distance = None
        if request.user.latitude and request.user.longitude and req.latitude and req.longitude:
            distance = calculate_distance(
                float(request.user.latitude), float(request.user.longitude),
                float(req.latitude), float(req.longitude)
            )
        
        request_list.append({
            'id': req.id,
            'victim': req.victim.username,
            'victim_id': req.victim.id,
            'disaster_id': req.disasters.id,
            'disaster_name': req.disasters.name,
            'description': req.description,
            'location': req.location,
            'latitude': float(req.latitude) if req.latitude else None,
            'longitude': float(req.longitude) if req.longitude else None,
            'assigned_volunteer_id': req.assigned_volunteer.id if req.assigned_volunteer else None,
            'assigned_volunteer_username': req.assigned_volunteer.username if req.assigned_volunteer else None,
            'status': req.status,
            'requested_at': req.requested_at.isoformat(),
            'distance_km': round(distance, 2) if distance else None
        })
    
    return Response({'help_requests': request_list})


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def create_help_request(request):
    """
    Create a new help request (victims only)
    Automatically finds nearby volunteers and suggests them
    """
    if request.user.role != 'victim':
        return Response({'error': 'Only victims can create help requests'}, status=status.HTTP_403_FORBIDDEN)
    
    try:
        disaster_id = request.data.get('disaster_id')
        description = request.data.get('description')
        location = request.data.get('location')
        latitude = request.data.get('latitude')
        longitude = request.data.get('longitude')
        
        if not disaster_id or not description or not location:
            return Response({'error': 'disaster_id, description, and location are required'}, status=status.HTTP_400_BAD_REQUEST)
        
        disaster = get_object_or_404(Disasters, id=disaster_id)
        
        # Use victim's location if not provided in request
        if not latitude and request.user.latitude:
            latitude = float(request.user.latitude)
        if not longitude and request.user.longitude:
            longitude = float(request.user.longitude)
        
        help_request = HelpRequest.objects.create(
            victim=request.user,
            disasters=disaster,
            description=description,
            location=location,
            latitude=latitude,
            longitude=longitude,
            status='pending'
        )
        
        # Find nearby volunteers
        nearby_volunteers = []
        if latitude and longitude:
            volunteers = find_nearby_volunteers(float(latitude), float(longitude), radius_km=50, max_results=5)
            nearby_volunteers = [{
                'id': v.id,
                'user_id': v.user.id,
                'username': v.user.username,
                'distance_km': round(calculate_distance(
                    float(latitude), float(longitude),
                    float(v.user.latitude), float(v.user.longitude)
                ), 2) if v.user.latitude and v.user.longitude else None
            } for v in volunteers]
        
        # Create status history
        HelpRequestStatusHistory.objects.create(
            help_request=help_request,
            previous_status='pending',
            new_status='pending',
            changed_by=request.user,
            note='Help request created'
        )
        
        return Response({
            'message': 'Help request created successfully',
            'help_request_id': help_request.id,
            'requested_at': help_request.requested_at.isoformat(),
            'nearby_volunteers': nearby_volunteers,
            'suggestion': 'You can assign a volunteer from the nearby volunteers list'
        }, status=status.HTTP_201_CREATED)
        
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['PUT', 'PATCH'])
@permission_classes([IsAuthenticated])
def update_help_request_status(request, request_id):
    """
    Update help request status
    - Super admin and camp admin can update any request
    - Volunteers can update requests assigned to them
    """
    try:
        new_status = request.data.get('status')
        note = request.data.get('note', '')
        
        if not new_status:
            return Response({'error': 'status is required'}, status=status.HTTP_400_BAD_REQUEST)
        
        help_request = get_object_or_404(HelpRequest, id=request_id)
        previous_status = help_request.status
        
        # Check permissions
        if request.user.role == 'volunteer':
            # Volunteers can only update requests assigned to them
            if help_request.assigned_volunteer != request.user:
                return Response({
                    'error': 'You can only update help requests assigned to you'
                }, status=status.HTTP_403_FORBIDDEN)
        elif request.user.role not in ['super_admin', 'camp_admin']:
            return Response({'error': 'Unauthorized. Admin or volunteer role required.'}, status=status.HTTP_403_FORBIDDEN)
        
        # Validate status
        valid_statuses = ['pending', 'in_progress', 'resolved', 'cancelled']
        if new_status not in valid_statuses:
            return Response({'error': f'Invalid status. Must be one of: {valid_statuses}'}, status=status.HTTP_400_BAD_REQUEST)
        
        help_request.status = new_status
        help_request.save()
        
        # Create status history
        HelpRequestStatusHistory.objects.create(
            help_request=help_request,
            previous_status=previous_status,
            new_status=new_status,
            changed_by=request.user,
            note=note
        )
        
        return Response({
            'message': 'Help request status updated successfully',
            'request_id': help_request.id,
            'previous_status': previous_status,
            'new_status': new_status,
            'updated_by': request.user.username
        })
        
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def assign_volunteer_to_help_request(request, request_id):
    """
    Assign a volunteer to a help request
    - Super admin can assign any volunteer
    - Can also auto-assign nearest volunteer
    """
    if request.user.role not in ['super_admin', 'camp_admin']:
        return Response({'error': 'Unauthorized. Admin role required.'}, status=status.HTTP_403_FORBIDDEN)
    
    try:
        volunteer_id = request.data.get('volunteer_id')
        auto_assign = request.data.get('auto_assign', False)
        
        help_request = get_object_or_404(HelpRequest, id=request_id)
        
        if auto_assign:
            # Auto-assign nearest available volunteer
            if help_request.latitude and help_request.longitude:
                volunteers = find_nearby_volunteers(
                    float(help_request.latitude), 
                    float(help_request.longitude),
                    radius_km=50,
                    max_results=1
                )
                if volunteers:
                    volunteer = volunteers[0]
                else:
                    return Response({
                        'error': 'No available volunteers found nearby'
                    }, status=status.HTTP_404_NOT_FOUND)
            else:
                return Response({
                    'error': 'Help request location not available for auto-assignment'
                }, status=status.HTTP_400_BAD_REQUEST)
        else:
            if not volunteer_id:
                return Response({'error': 'volunteer_id is required when auto_assign is false'}, status=status.HTTP_400_BAD_REQUEST)
            volunteer_user = get_object_or_404(User, id=volunteer_id, role='volunteer')
            volunteer = get_object_or_404(Volunteer, user=volunteer_user)
        
        # Assign volunteer
        help_request.assigned_volunteer = volunteer.user
        help_request.status = 'in_progress'
        help_request.save()
        
        # Create task assignment
        task = TaskAssignment.objects.create(
            volunteer=volunteer.user,
            help_request=help_request,
            task_description=f"Help victim: {help_request.description[:100]}",
            status='assigned'
        )
        
        # Create status history
        HelpRequestStatusHistory.objects.create(
            help_request=help_request,
            previous_status='pending',
            new_status='in_progress',
            changed_by=request.user,
            note=f'Assigned to volunteer: {volunteer.user.username}'
        )
        
        return Response({
            'message': 'Volunteer assigned successfully',
            'help_request_id': help_request.id,
            'volunteer_id': volunteer.user.id,
            'volunteer_username': volunteer.user.username,
            'task_id': task.id,
            'status': help_request.status
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# ========================================
# TASK ASSIGNMENT MANAGEMENT VIEWS
# ========================================

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def list_task_assignments(request):
    """
    List all task assignments
    """
    tasks = TaskAssignment.objects.all()
    
    # Filter by status
    status_filter = request.GET.get('status')
    if status_filter:
        tasks = tasks.filter(status=status_filter)
    
    # Filter by volunteer
    volunteer_id = request.GET.get('volunteer_id')
    if volunteer_id:
        tasks = tasks.filter(volunteer_id=volunteer_id)
    
    # If user is volunteer, show only their tasks
    if request.user.role == 'volunteer':
        tasks = tasks.filter(volunteer=request.user)
    
    tasks = tasks.order_by('-assigned_at')
    
    task_list = []
    for task in tasks:
        task_list.append({
            'id': task.id,
            'volunteer': task.volunteer.username,
            'volunteer_id': task.volunteer.id,
            'task_description': task.task_description,
            'help_request_id': task.help_request.id if task.help_request else None,
            'status': task.status,
            'assigned_at': task.assigned_at.isoformat()
        })
    
    return Response({'task_assignments': task_list})


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def create_task_assignment(request):
    """
    Create a new task assignment (admin only)
    """
    if request.user.role not in ['super_admin', 'camp_admin']:
        return Response({'error': 'Unauthorized. Admin role required.'}, status=status.HTTP_403_FORBIDDEN)
    
    try:
        volunteer_id = request.data.get('volunteer_id')
        task_description = request.data.get('task_description')
        help_request_id = request.data.get('help_request_id')
        
        if not volunteer_id or not task_description:
            return Response({'error': 'volunteer_id and task_description are required'}, status=status.HTTP_400_BAD_REQUEST)
        
        volunteer = get_object_or_404(User, id=volunteer_id, role='volunteer')
        help_request = None
        if help_request_id:
            help_request = get_object_or_404(HelpRequest, id=help_request_id)
        
        task = TaskAssignment.objects.create(
            volunteer=volunteer,
            task_description=task_description,
            help_request=help_request,
            status='assigned'
        )
        
        # Create status history
        TaskAssignmentStatusHistory.objects.create(
            task=task,
            previous_status='assigned',
            new_status='assigned',
            changed_by=request.user,
            note='Task assigned'
        )
        
        return Response({
            'message': 'Task assigned successfully',
            'task_id': task.id,
            'assigned_at': task.assigned_at.isoformat()
        }, status=status.HTTP_201_CREATED)
        
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['PUT', 'PATCH'])
@permission_classes([IsAuthenticated])
def update_task_status(request, task_id):
    """
    Update task status (volunteer can update their own tasks, admin can update any)
    """
    try:
        new_status = request.data.get('status')
        note = request.data.get('note', '')
        
        if not new_status:
            return Response({'error': 'status is required'}, status=status.HTTP_400_BAD_REQUEST)
        
        task = get_object_or_404(TaskAssignment, id=task_id)
        
        # Check permissions
        if request.user.role == 'volunteer' and task.volunteer != request.user:
            return Response({'error': 'You can only update your own tasks'}, status=status.HTTP_403_FORBIDDEN)
        if request.user.role not in ['super_admin', 'camp_admin', 'volunteer']:
            return Response({'error': 'Unauthorized'}, status=status.HTTP_403_FORBIDDEN)
        
        previous_status = task.status
        
        # Validate status
        valid_statuses = ['assigned', 'in_progress', 'completed', 'cancelled']
        if new_status not in valid_statuses:
            return Response({'error': f'Invalid status. Must be one of: {valid_statuses}'}, status=status.HTTP_400_BAD_REQUEST)
        
        task.status = new_status
        task.save()
        
        # Create status history
        TaskAssignmentStatusHistory.objects.create(
            task=task,
            previous_status=previous_status,
            new_status=new_status,
            changed_by=request.user,
            note=note
        )
        
        return Response({
            'message': 'Task status updated successfully',
            'task_id': task.id,
            'previous_status': previous_status,
            'new_status': new_status
        })
        
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# ========================================
# TRANSPORT MANAGEMENT VIEWS
# ========================================

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def list_transports(request):
    """
    List all transports
    """
    transports = Transport.objects.all()
    
    # Filter by status
    status_filter = request.GET.get('status')
    if status_filter:
        transports = transports.filter(status=status_filter)
    
    # Filter by transport type
    transport_type = request.GET.get('transport_type')
    if transport_type:
        transports = transports.filter(transport_type=transport_type)
    
    transport_list = []
    for transport in transports:
        transport_list.append({
            'id': transport.id,
            'vehicle_number': transport.vehicle_number,
            'transport_type': transport.transport_type,
            'capacity': float(transport.capacity),
            'status': transport.status,
            'current_location': transport.current_location,
            'assigned_to_camp_id': transport.assigned_to_camp.id if transport.assigned_to_camp else None,
            'assigned_to_camp_name': transport.assigned_to_camp.name if transport.assigned_to_camp else None,
            'last_service_date': transport.last_service_date.isoformat() if transport.last_service_date else None,
            'created_at': transport.created_at.isoformat()
        })
    
    return Response({'transports': transport_list})


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def available_transports(request):
    """
    Get all available transports
    """
    transports = Transport.objects.filter(status='available')
    
    transport_list = []
    for transport in transports:
        transport_list.append({
            'id': transport.id,
            'vehicle_number': transport.vehicle_number,
            'transport_type': transport.transport_type,
            'capacity': float(transport.capacity),
            'current_location': transport.current_location
        })
    
    return Response({'available_transports': transport_list})


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def my_donations(request):
    """
    Get all donations made by the current donor
    """
    if request.user.role != 'donor':
        return Response({'error': 'Only donors can view their donations'}, status=status.HTTP_403_FORBIDDEN)
    
    donations = Donation.objects.filter(created_by=request.user).order_by('-donation_date')
    
    donation_list = []
    for donation in donations:
        items = donation.items.all()
        donation_list.append({
            'id': donation.id,
            'donor_name': donation.donor_name,
            'donor_type': donation.donor_type,
            'camp_id': donation.camp.id if donation.camp else None,
            'camp_name': donation.camp.name if donation.camp else None,
            'camp_location': donation.camp.location if donation.camp else None,
            'status': donation.status,
            'donation_date': donation.donation_date.isoformat(),
            'items': [{
                'id': item.id,
                'resource_name': item.resource.name if item.resource else None,
                'resource_id': item.resource.id if item.resource else None,
                'quantity': float(item.quantity),
                'unit': item.resource.unit if item.resource else None
            } for item in items],
            'has_acknowledgment': hasattr(donation, 'donationacknowledgment'),
            'acknowledgment': {
                'text': donation.donationacknowledgment.acknowledgment_text,
                'acknowledged_by': donation.donationacknowledgment.acknowledged_by.username if hasattr(donation, 'donationacknowledgment') and donation.donationacknowledgment.acknowledged_by else None,
                'acknowledged_at': donation.donationacknowledgment.acknowledged_at.isoformat() if hasattr(donation, 'donationacknowledgment') else None
            } if hasattr(donation, 'donationacknowledgment') else None
        })
    
    return Response({'my_donations': donation_list, 'total': len(donation_list)})


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def camp_donations(request, camp_id):
    """
    Get all donations for a specific camp (camp admin can see donations for their camp)
    """
    camp = get_object_or_404(Camp, id=camp_id)
    
    # If camp_admin, ensure they can only see donations for their camp
    if request.user.role == 'camp_admin':
        try:
            camp_admin = CampAdmin.objects.get(user=request.user)
            if camp_admin.camp != camp:
                return Response({
                    'error': 'You can only view donations for your own camp'
                }, status=status.HTTP_403_FORBIDDEN)
        except CampAdmin.DoesNotExist:
            return Response({'error': 'Camp admin profile not found'}, status=status.HTTP_403_FORBIDDEN)
    elif request.user.role not in ['super_admin', 'camp_admin', 'donor']:
        return Response({'error': 'Unauthorized'}, status=status.HTTP_403_FORBIDDEN)
    
    donations = Donation.objects.filter(camp=camp).order_by('-donation_date')
    
    # Filter by status if provided
    status_filter = request.GET.get('status')
    if status_filter:
        donations = donations.filter(status=status_filter)
    
    donation_list = []
    for donation in donations:
        items = donation.items.all()
        donation_list.append({
            'id': donation.id,
            'donor_name': donation.donor_name,
            'donor_type': donation.donor_type,
            'contact_email': donation.contact_email,
            'contact_phone': donation.contact_phone,
            'status': donation.status,
            'donation_date': donation.donation_date.isoformat(),
            'items': [{
                'id': item.id,
                'resource_name': item.resource.name if item.resource else None,
                'resource_id': item.resource.id if item.resource else None,
                'quantity': float(item.quantity),
                'unit': item.resource.unit if item.resource else None
            } for item in items],
            'has_acknowledgment': hasattr(donation, 'donationacknowledgment'),
            'acknowledgment': {
                'text': donation.donationacknowledgment.acknowledgment_text,
                'acknowledged_by': donation.donationacknowledgment.acknowledged_by.username if hasattr(donation, 'donationacknowledgment') and donation.donationacknowledgment.acknowledged_by else None,
                'acknowledged_at': donation.donationacknowledgment.acknowledged_at.isoformat() if hasattr(donation, 'donationacknowledgment') else None
            } if hasattr(donation, 'donationacknowledgment') else None
        })
    
    return Response({
        'camp_id': camp.id,
        'camp_name': camp.name,
        'donations': donation_list,
        'total': len(donation_list),
        'pending': donations.filter(status='pending').count(),
        'accepted': donations.filter(status='accepted').count(),
        'rejected': donations.filter(status='rejected').count()
    })


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def list_transport_trips(request):
    """
    List all transport trips
    """
    trips = TransportTrip.objects.all()
    
    # Filter by status
    status_filter = request.GET.get('status')
    if status_filter:
        trips = trips.filter(status=status_filter)
    
    trips = trips.order_by('-departure_time')
    
    trip_list = []
    for trip in trips:
        trip_list.append({
            'id': trip.id,
            'transport_id': trip.transport.id,
            'vehicle_number': trip.transport.vehicle_number,
            'origin': trip.origin,
            'destination': trip.destination,
            'departure_time': trip.departure_time.isoformat(),
            'arrival_time': trip.arrival_time.isoformat() if trip.arrival_time else None,
            'status': trip.status,
            'cargo_description': trip.cargo_description,
            'notes': trip.notes,
            'created_at': trip.created_at.isoformat()
        })
    
    return Response({'transport_trips': trip_list})
