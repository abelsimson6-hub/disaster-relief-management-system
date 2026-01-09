from django.shortcuts import render, get_object_or_404
from django.http import JsonResponse
from django.views.decorators.http import require_http_methods
from django.views.decorators.csrf import csrf_exempt
from django.contrib.auth.decorators import login_required
from django.db.models import Q, Count, Sum, Avg
from django.utils import timezone
from datetime import timedelta
import json

from .models import Camp
from disasters.models import Disasters
from relief.models import ResourceRequest
from users.models import User, CampAdmin


# ========================================
# CAMP MANAGEMENT VIEWS
# ========================================

@login_required
@require_http_methods(["GET"])
def list_camps(request):
    """
    List all camps with optional filtering
    - Can filter by location (e.g., ?location=thrissur)
    - Can filter by status, type, disaster
    """
    camps = Camp.objects.all()
    
    # Filter by location (case-insensitive partial match)
    location_filter = request.GET.get('location')
    if location_filter:
        camps = camps.filter(location__icontains=location_filter)
    
    # Filter by status
    status_filter = request.GET.get('status')
    if status_filter:
        camps = camps.filter(status=status_filter)
    
    # Filter by camp type
    camp_type = request.GET.get('camp_type')
    if camp_type:
        camps = camps.filter(camp_type=camp_type)
    
    # Filter by disaster
    disaster_id = request.GET.get('disaster_id')
    if disaster_id:
        camps = camps.filter(disasters_id=disaster_id)
    
    # If user is camp_admin, show only their camp
    if request.user.role == 'camp_admin':
        try:
            camp_admin = CampAdmin.objects.get(user=request.user)
            camps = Camp.objects.filter(id=camp_admin.camp.id)
        except CampAdmin.DoesNotExist:
            camps = Camp.objects.none()
    
    camps = camps.order_by('name')
    
    camp_list = []
    for camp in camps:
        camp_list.append({
            'id': camp.id,
            'name': camp.name,
            'camp_type': camp.camp_type,
            'disaster_id': camp.disasters.id,
            'disaster_name': camp.disasters.name,
            'location': camp.location,
            'latitude': float(camp.latitude) if camp.latitude else None,
            'longitude': float(camp.longitude) if camp.longitude else None,
            'capacity': camp.capacity,
            'population_capacity': camp.population_capacity,
            'contact_person': camp.contact_person,
            'contact_phone': camp.contact_phone,
            'email': camp.email,
            'status': camp.status,
            'coverage_radius_km': float(camp.coverage_radius_km) if camp.coverage_radius_km else None,
            'service_area_description': camp.service_area_description,
            'created_at': camp.created_at.isoformat(),
            'updated_at': camp.updated_at.isoformat()
        })
    
    return JsonResponse({'camps': camp_list}, safe=False)


@login_required
@require_http_methods(["GET"])
def get_camp(request, camp_id):
    """
    Get a specific camp by ID with related information
    """
    camp = get_object_or_404(Camp, id=camp_id)
    
    # Get camp admins
    camp_admins = CampAdmin.objects.filter(camp=camp)
    admin_list = [{
        'id': admin.user.id,
        'username': admin.user.username,
        'assigned_at': admin.assigned_at.isoformat()
    } for admin in camp_admins]
    
    # Get resource requests (requirements) - visible to donors
    resource_requests = ResourceRequest.objects.filter(camp=camp)
    request_list = [{
        'id': req.id,
        'resource_name': req.resource.name,
        'resource_id': req.resource.id,
        'resource_category': req.resource.category,
        'quantity_requested': float(req.quantity_requested),
        'quantity_fulfilled': float(req.quantity_fulfilled),
        'quantity_needed': float(req.quantity_requested - req.quantity_fulfilled),
        'unit': req.resource.unit,
        'priority': req.priority,
        'status': req.status,
        'needed_by': req.needed_by.isoformat(),
        'reason': req.reason
    } for req in resource_requests]
    
    # Get pending donations (for camp admins)
    pending_donations = []
    if request.user.role in ['super_admin', 'camp_admin']:
        from operations.models import Donation
        donations = Donation.objects.filter(camp=camp, status='pending').order_by('-donation_date')
        pending_donations = [{
            'id': donation.id,
            'donor_name': donation.donor_name,
            'donor_type': donation.donor_type,
            'items': [{
                'resource_name': item.resource.name if item.resource else None,
                'quantity': float(item.quantity)
            } for item in donation.items.all()],
            'donation_date': donation.donation_date.isoformat()
        } for donation in donations]
    
    return JsonResponse({
        'id': camp.id,
        'name': camp.name,
        'camp_type': camp.camp_type,
        'disaster_id': camp.disasters.id,
        'disaster_name': camp.disasters.name,
        'location': camp.location,
        'latitude': float(camp.latitude) if camp.latitude else None,
        'longitude': float(camp.longitude) if camp.longitude else None,
        'capacity': camp.capacity,
        'population_capacity': camp.population_capacity,
        'contact_person': camp.contact_person,
        'contact_phone': camp.contact_phone,
        'email': camp.email,
        'status': camp.status,
        'coverage_radius_km': float(camp.coverage_radius_km) if camp.coverage_radius_km else None,
        'service_area_description': camp.service_area_description,
        'created_at': camp.created_at.isoformat(),
        'updated_at': camp.updated_at.isoformat(),
        'camp_admins': admin_list,
        'resource_requests': request_list,  # Requirements that donors can see
        'pending_donations': pending_donations,  # Only visible to admins
        'statistics': {
            'total_resource_requests': resource_requests.count(),
            'pending_requests': resource_requests.filter(status='pending').count(),
            'fulfilled_requests': resource_requests.filter(status='fulfilled').count(),
            'urgent_requests': resource_requests.filter(priority='urgent', status='pending').count(),
            'pending_donations_count': len(pending_donations)
        }
    })


@login_required
@require_http_methods(["POST"])
@csrf_exempt
def create_camp(request):
    """
    Create a new camp (super admin only)
    """
    if request.user.role != 'super_admin':
        return JsonResponse({'error': 'Unauthorized. Super admin role required.'}, status=403)
    
    try:
        data = json.loads(request.body)
        
        name = data.get('name')
        camp_type = data.get('camp_type')
        disaster_id = data.get('disaster_id')
        location = data.get('location')
        capacity = data.get('capacity')
        contact_person = data.get('contact_person')
        contact_phone = data.get('contact_phone')
        
        if not name or not camp_type or not disaster_id or not location or not capacity or not contact_person or not contact_phone:
            return JsonResponse({
                'error': 'name, camp_type, disaster_id, location, capacity, contact_person, and contact_phone are required'
            }, status=400)
        
        disaster = get_object_or_404(Disasters, id=disaster_id)
        
        # Validate choices
        valid_types = ['shelter', 'medical', 'distribution', 'evacuation', 'rescue']
        valid_statuses = ['active', 'full', 'closed', 'maintenance']
        
        if camp_type not in valid_types:
            return JsonResponse({'error': f'Invalid camp_type. Must be one of: {valid_types}'}, status=400)
        
        camp = Camp.objects.create(
            name=name,
            camp_type=camp_type,
            disasters=disaster,
            location=location,
            latitude=data.get('latitude'),
            longitude=data.get('longitude'),
            capacity=capacity,
            population_capacity=data.get('population_capacity', 0),
            contact_person=contact_person,
            contact_phone=contact_phone,
            email=data.get('email', ''),
            status=data.get('status', 'active'),
            coverage_radius_km=data.get('coverage_radius_km'),
            service_area_description=data.get('service_area_description', '')
        )
        
        return JsonResponse({
            'message': 'Camp created successfully',
            'camp_id': camp.id,
            'created_at': camp.created_at.isoformat()
        }, status=201)
        
    except json.JSONDecodeError:
        return JsonResponse({'error': 'Invalid JSON'}, status=400)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)


@login_required
@require_http_methods(["PUT", "PATCH"])
@csrf_exempt
def update_camp(request, camp_id):
    """
    Update a camp (admin only)
    """
    if request.user.role not in ['super_admin', 'camp_admin']:
        return JsonResponse({'error': 'Unauthorized. Admin role required.'}, status=403)
    
    try:
        data = json.loads(request.body)
        camp = get_object_or_404(Camp, id=camp_id)
        
        # Check if camp_admin can only update their own camp
        if request.user.role == 'camp_admin':
            try:
                camp_admin = CampAdmin.objects.get(user=request.user)
                if camp_admin.camp != camp:
                    return JsonResponse({'error': 'You can only update your own camp'}, status=403)
            except CampAdmin.DoesNotExist:
                return JsonResponse({'error': 'Camp admin profile not found'}, status=403)
        
        # Update fields if provided
        if 'name' in data:
            camp.name = data['name']
        if 'camp_type' in data:
            valid_types = ['shelter', 'medical', 'distribution', 'evacuation', 'rescue']
            if data['camp_type'] not in valid_types:
                return JsonResponse({'error': f'Invalid camp_type. Must be one of: {valid_types}'}, status=400)
            camp.camp_type = data['camp_type']
        if 'location' in data:
            camp.location = data['location']
        if 'latitude' in data:
            camp.latitude = data['latitude']
        if 'longitude' in data:
            camp.longitude = data['longitude']
        if 'capacity' in data:
            camp.capacity = data['capacity']
        if 'population_capacity' in data:
            camp.population_capacity = data['population_capacity']
        if 'contact_person' in data:
            camp.contact_person = data['contact_person']
        if 'contact_phone' in data:
            camp.contact_phone = data['contact_phone']
        if 'email' in data:
            camp.email = data['email']
        if 'status' in data:
            valid_statuses = ['active', 'full', 'closed', 'maintenance']
            if data['status'] not in valid_statuses:
                return JsonResponse({'error': f'Invalid status. Must be one of: {valid_statuses}'}, status=400)
            camp.status = data['status']
        if 'coverage_radius_km' in data:
            camp.coverage_radius_km = data['coverage_radius_km']
        if 'service_area_description' in data:
            camp.service_area_description = data['service_area_description']
        
        camp.save()
        
        return JsonResponse({
            'message': 'Camp updated successfully',
            'camp_id': camp.id,
            'updated_at': camp.updated_at.isoformat()
        })
        
    except json.JSONDecodeError:
        return JsonResponse({'error': 'Invalid JSON'}, status=400)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)


@login_required
@require_http_methods(["GET"])
def active_camps(request):
    """
    Get all active camps
    """
    camps = Camp.objects.filter(status='active').order_by('name')
    
    camp_list = []
    for camp in camps:
        camp_list.append({
            'id': camp.id,
            'name': camp.name,
            'camp_type': camp.camp_type,
            'location': camp.location,
            'capacity': camp.capacity,
            'population_capacity': camp.population_capacity,
            'disaster_name': camp.disasters.name
        })
    
    return JsonResponse({'active_camps': camp_list}, safe=False)


@login_required
@require_http_methods(["GET"])
def camp_statistics(request):
    """
    Get camp statistics
    """
    stats = {
        'total_camps': Camp.objects.count(),
        'active_camps': Camp.objects.filter(status='active').count(),
        'full_camps': Camp.objects.filter(status='full').count(),
        'closed_camps': Camp.objects.filter(status='closed').count(),
        'camps_by_type': list(
            Camp.objects.values('camp_type')
            .annotate(count=Count('id'))
            .order_by('-count')
        ),
        'total_capacity': Camp.objects.aggregate(total=Sum('capacity'))['total'] or 0,
        'total_population_capacity': Camp.objects.aggregate(total=Sum('population_capacity'))['total'] or 0,
        'camps_by_disaster': list(
            Camp.objects.values('disasters__name')
            .annotate(count=Count('id'))
            .order_by('-count')
        )
    }
    
    return JsonResponse(stats)


@login_required
@require_http_methods(["GET"])
def camp_capacity_report(request):
    """
    Get capacity report for all camps
    """
    camps = Camp.objects.all().order_by('name')
    
    capacity_report = []
    for camp in camps:
        capacity_report.append({
            'id': camp.id,
            'name': camp.name,
            'camp_type': camp.camp_type,
            'location': camp.location,
            'capacity': camp.capacity,
            'population_capacity': camp.population_capacity,
            'status': camp.status,
            'utilization_percentage': (
                (camp.population_capacity / camp.capacity * 100) if camp.capacity > 0 else 0
            )
        })
    
    return JsonResponse({'capacity_report': capacity_report}, safe=False)
