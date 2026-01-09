from django.shortcuts import render, get_object_or_404
from django.http import JsonResponse
from django.views.decorators.http import require_http_methods
from django.views.decorators.csrf import csrf_exempt
from django.contrib.auth.decorators import login_required
from django.db.models import Q, Count, Sum, Avg
from django.utils import timezone
from datetime import timedelta
import json
# DRF imports for JWT support
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status

from .models import Resource, ResourceRequest, ResourceRequestStatusHistory, ResourceInventoryTransaction
from operations.utils import find_nearest_camp_admin, find_nearest_camp
from shelters.models import Camp
from users.models import User, CampAdmin


# ========================================
# RESOURCE MANAGEMENT VIEWS
# ========================================

@login_required
@require_http_methods(["GET"])
def list_resources(request):
    """
    List all resources with optional filtering
    """
    resources = Resource.objects.all()
    
    # Filter by category
    category = request.GET.get('category')
    if category:
        resources = resources.filter(category=category)
    
    # Filter by active status
    is_active = request.GET.get('is_active')
    if is_active is not None:
        resources = resources.filter(is_active=is_active.lower() == 'true')
    
    resources = resources.order_by('category', 'name')
    
    resource_list = []
    for resource in resources:
        resource_list.append({
            'id': resource.id,
            'name': resource.name,
            'category': resource.category,
            'description': resource.description,
            'unit': resource.unit,
            'total_quantity': float(resource.total_quantity),
            'available_quantity': float(resource.available_quantity),
            'is_active': resource.is_active,
            'created_at': resource.created_at.isoformat()
        })
    
    return JsonResponse({'resources': resource_list}, safe=False)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_resource(request, resource_id):
    """
    Get a specific resource by ID with inventory history
    """
    resource = get_object_or_404(Resource, id=resource_id)
    
    # Get recent inventory transactions
    recent_transactions = ResourceInventoryTransaction.objects.filter(
        resource=resource
    ).order_by('-created_at')[:10]
    
    transactions = [{
        'id': t.id,
        'transaction_type': t.transaction_type,
        'quantity_delta': float(t.quantity_delta),
        'reason': t.reason,
        'created_by': t.created_by.username if t.created_by else None,
        'created_at': t.created_at.isoformat()
    } for t in recent_transactions]
    
    return Response({
        'id': resource.id,
        'name': resource.name,
        'category': resource.category,
        'description': resource.description,
        'unit': resource.unit,
        'total_quantity': float(resource.total_quantity),
        'available_quantity': float(resource.available_quantity),
        'is_active': resource.is_active,
        'created_at': resource.created_at.isoformat(),
        'recent_transactions': transactions
    })


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def create_resource(request):
    """
    Create a new resource (admin only)
    """
    if request.user.role not in ['super_admin', 'camp_admin']:
        return Response({'error': 'Unauthorized. Admin role required.'}, status=status.HTTP_403_FORBIDDEN)
    
    try:
        name = request.data.get('name')
        category = request.data.get('category')
        unit = request.data.get('unit')
        total_quantity = request.data.get('total_quantity', 0)
        
        if not name or not category or not unit:
            return Response({'error': 'name, category, and unit are required'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Validate choices
        valid_categories = ['food', 'water', 'medical', 'clothing', 'shelter', 'hygiene', 'equipment', 'other']
        valid_units = ['kg', 'g', 'l', 'ml', 'piece', 'box', 'pack', 'unit']
        
        if category not in valid_categories:
            return Response({'error': f'Invalid category. Must be one of: {valid_categories}'}, status=status.HTTP_400_BAD_REQUEST)
        if unit not in valid_units:
            return Response({'error': f'Invalid unit. Must be one of: {valid_units}'}, status=status.HTTP_400_BAD_REQUEST)
        
        resource = Resource.objects.create(
            name=name,
            category=category,
            description=request.data.get('description', ''),
            unit=unit,
            total_quantity=total_quantity,
            available_quantity=total_quantity,
            is_active=request.data.get('is_active', True)
        )
        
        # Create inventory transaction
        if total_quantity > 0:
            ResourceInventoryTransaction.objects.create(
                resource=resource,
                transaction_type='add',
                quantity_delta=total_quantity,
                reason='Initial resource creation',
                created_by=request.user
            )
        
        return Response({
            'message': 'Resource created successfully',
            'resource_id': resource.id,
            'created_at': resource.created_at.isoformat()
        }, status=status.HTTP_201_CREATED)
        
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['PUT', 'PATCH'])
@permission_classes([IsAuthenticated])
def update_resource(request, resource_id):
    """
    Update a resource (admin only)
    """
    if request.user.role not in ['super_admin', 'camp_admin']:
        return Response({'error': 'Unauthorized. Admin role required.'}, status=status.HTTP_403_FORBIDDEN)
    
    try:
        resource = get_object_or_404(Resource, id=resource_id)
        
        # Update fields if provided
        if 'name' in request.data:
            resource.name = request.data['name']
        if 'category' in request.data:
            valid_categories = ['food', 'water', 'medical', 'clothing', 'shelter', 'hygiene', 'equipment', 'other']
            if request.data['category'] not in valid_categories:
                return Response({'error': f'Invalid category. Must be one of: {valid_categories}'}, status=status.HTTP_400_BAD_REQUEST)
            resource.category = request.data['category']
        if 'description' in request.data:
            resource.description = request.data['description']
        if 'unit' in request.data:
            valid_units = ['kg', 'g', 'l', 'ml', 'piece', 'box', 'pack', 'unit']
            if request.data['unit'] not in valid_units:
                return Response({'error': f'Invalid unit. Must be one of: {valid_units}'}, status=status.HTTP_400_BAD_REQUEST)
            resource.unit = request.data['unit']
        if 'is_active' in request.data:
            resource.is_active = request.data['is_active']
        
        resource.save()
        
        return Response({
            'message': 'Resource updated successfully',
            'resource_id': resource.id
        })
        
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def adjust_inventory(request, resource_id):
    """
    Adjust resource inventory (admin only)
    """
    if request.user.role not in ['super_admin', 'camp_admin']:
        return Response({'error': 'Unauthorized. Admin role required.'}, status=status.HTTP_403_FORBIDDEN)
    
    try:
        quantity_delta = request.data.get('quantity_delta')
        reason = request.data.get('reason', 'Manual adjustment')
        transaction_type = request.data.get('transaction_type', 'adjust')
        
        if quantity_delta is None:
            return Response({'error': 'quantity_delta is required'}, status=status.HTTP_400_BAD_REQUEST)
        
        resource = get_object_or_404(Resource, id=resource_id)
        
        # Validate transaction type
        valid_types = ['add', 'remove', 'adjust', 'fulfillment', 'donation']
        if transaction_type not in valid_types:
            return Response({'error': f'Invalid transaction_type. Must be one of: {valid_types}'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Update inventory
        if transaction_type == 'add':
            resource.total_quantity += quantity_delta
            resource.available_quantity += quantity_delta
        elif transaction_type == 'remove':
            resource.available_quantity -= quantity_delta
            if resource.available_quantity < 0:
                return Response({'error': 'Insufficient available quantity'}, status=status.HTTP_400_BAD_REQUEST)
        else:  # adjust
            resource.available_quantity += quantity_delta
            if resource.available_quantity < 0:
                return Response({'error': 'Insufficient available quantity'}, status=status.HTTP_400_BAD_REQUEST)
        
        resource.save()
        
        # Create transaction record
        ResourceInventoryTransaction.objects.create(
            resource=resource,
            transaction_type=transaction_type,
            quantity_delta=quantity_delta,
            reason=reason,
            created_by=request.user
        )
        
        return Response({
            'message': 'Inventory adjusted successfully',
            'resource_id': resource.id,
            'new_available_quantity': float(resource.available_quantity),
            'new_total_quantity': float(resource.total_quantity)
        })
        
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# ========================================
# RESOURCE REQUEST MANAGEMENT VIEWS
# ========================================

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def list_resource_requests(request):
    """
    List all resource requests
    """
    requests = ResourceRequest.objects.all()
    
    # Filter by status
    status_filter = request.GET.get('status')
    if status_filter:
        requests = requests.filter(status=status_filter)
    
    # Filter by priority
    priority = request.GET.get('priority')
    if priority:
        requests = requests.filter(priority=priority)
    
    # Filter by camp
    camp_id = request.GET.get('camp_id')
    if camp_id:
        requests = requests.filter(camp_id=camp_id)
    
    # If user is camp_admin, show only their camp's requests
    if request.user.role == 'camp_admin':
        from users.models import CampAdmin
        try:
            camp_admin = CampAdmin.objects.get(user=request.user)
            requests = requests.filter(camp=camp_admin.camp)
        except CampAdmin.DoesNotExist:
            requests = ResourceRequest.objects.none()
    
    requests = requests.order_by('-request_date')
    
    request_list = []
    for req in requests:
        request_list.append({
            'id': req.id,
            'camp_id': req.camp.id,
            'camp_name': req.camp.name,
            'resource_id': req.resource.id,
            'resource_name': req.resource.name,
            'quantity_requested': float(req.quantity_requested),
            'quantity_fulfilled': float(req.quantity_fulfilled),
            'priority': req.priority,
            'status': req.status,
            'requested_by': req.requested_by.username,
            'request_date': req.request_date.isoformat(),
            'needed_by': req.needed_by.isoformat(),
            'reason': req.reason
        })
    
    return Response({'resource_requests': request_list})


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def create_resource_request(request):
    """
    Create a new resource request
    - Camp admin can create for their camp
    - Super admin can create for any camp
    - Victims can create requests (auto-assigned to nearest camp admin)
    """
    try:
        camp_id = request.data.get('camp_id')
        resource_id = request.data.get('resource_id')
        quantity_requested = request.data.get('quantity_requested')
        priority = request.data.get('priority', 'medium')
        needed_by = request.data.get('needed_by')
        reason = request.data.get('reason', '')
        
        if not resource_id or not quantity_requested or not needed_by:
            return Response({
                'error': 'resource_id, quantity_requested, and needed_by are required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        resource = get_object_or_404(Resource, id=resource_id)
        
        # Determine camp
        if request.user.role == 'victim':
            # For victims, find nearest camp automatically
            if not request.user.latitude or not request.user.longitude:
                return Response({
                    'error': 'Your location is required. Please update your profile with location.'
                }, status=status.HTTP_400_BAD_REQUEST)
            
            camp = find_nearest_camp(
                float(request.user.latitude),
                float(request.user.longitude),
                radius_km=100
            )
            
            if not camp:
                return Response({
                    'error': 'No active camp found nearby. Please contact admin.'
                }, status=status.HTTP_404_NOT_FOUND)
        elif request.user.role == 'camp_admin':
            # Camp admin must specify their camp
            if not camp_id:
                return Response({'error': 'camp_id is required'}, status=status.HTTP_400_BAD_REQUEST)
            camp = get_object_or_404(Camp, id=camp_id)
            
            # Verify it's their camp
            try:
                camp_admin = CampAdmin.objects.get(user=request.user)
                if camp_admin.camp != camp:
                    return Response({
                        'error': 'You can only create resource requests for your own camp'
                    }, status=status.HTTP_403_FORBIDDEN)
            except CampAdmin.DoesNotExist:
                return Response({'error': 'Camp admin profile not found'}, status=status.HTTP_403_FORBIDDEN)
        elif request.user.role == 'super_admin':
            # Super admin must specify camp
            if not camp_id:
                return Response({'error': 'camp_id is required'}, status=status.HTTP_400_BAD_REQUEST)
            camp = get_object_or_404(Camp, id=camp_id)
        else:
            return Response({'error': 'Unauthorized. Only victims, camp admins, and super admins can create resource requests.'}, status=status.HTTP_403_FORBIDDEN)
        
        # Validate priority
        valid_priorities = ['low', 'medium', 'high', 'urgent']
        if priority not in valid_priorities:
            return Response({'error': f'Invalid priority. Must be one of: {valid_priorities}'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Parse needed_by
        from django.utils.dateparse import parse_datetime
        needed_by_datetime = parse_datetime(needed_by)
        if not needed_by_datetime:
            return Response({'error': 'Invalid needed_by format. Use ISO format.'}, status=status.HTTP_400_BAD_REQUEST)
        
        request_obj = ResourceRequest.objects.create(
            camp=camp,
            resource=resource,
            quantity_requested=quantity_requested,
            priority=priority,
            status='pending',
            requested_by=request.user,
            needed_by=needed_by_datetime,
            reason=reason
        )
        
        # Create status history
        ResourceRequestStatusHistory.objects.create(
            request=request_obj,
            previous_status='pending',
            new_status='pending',
            changed_by=request.user,
            note='Resource request created'
        )
        
        return Response({
            'message': 'Resource request created successfully',
            'request_id': request_obj.id,
            'camp_name': camp.name,
            'request_date': request_obj.request_date.isoformat()
        }, status=status.HTTP_201_CREATED)
        
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['PUT', 'PATCH'])
@permission_classes([IsAuthenticated])
def update_resource_request_status(request, request_id):
    """
    Update resource request status (admin only)
    """
    if request.user.role not in ['super_admin', 'camp_admin']:
        return Response({'error': 'Unauthorized. Admin role required.'}, status=status.HTTP_403_FORBIDDEN)
    
    try:
        new_status = request.data.get('status')
        quantity_fulfilled = request.data.get('quantity_fulfilled')
        note = request.data.get('note', '')
        
        if not new_status:
            return Response({'error': 'status is required'}, status=status.HTTP_400_BAD_REQUEST)
        
        request_obj = get_object_or_404(ResourceRequest, id=request_id)
        
        # If camp_admin, ensure they can only update requests for their own camp
        if request.user.role == 'camp_admin':
            from users.models import CampAdmin
            try:
                camp_admin = CampAdmin.objects.get(user=request.user)
                if camp_admin.camp != request_obj.camp:
                    return Response({
                        'error': 'You can only update resource requests for your own camp'
                    }, status=status.HTTP_403_FORBIDDEN)
            except CampAdmin.DoesNotExist:
                return Response({'error': 'Camp admin profile not found'}, status=status.HTTP_403_FORBIDDEN)
        previous_status = request_obj.status
        
        # Validate status
        valid_statuses = ['pending', 'approved', 'rejected', 'fulfilled', 'cancelled']
        if new_status not in valid_statuses:
            return Response({'error': f'Invalid status. Must be one of: {valid_statuses}'}, status=status.HTTP_400_BAD_REQUEST)
        
        request_obj.status = new_status
        if quantity_fulfilled is not None:
            if quantity_fulfilled > request_obj.quantity_requested:
                return Response({'error': 'quantity_fulfilled cannot exceed quantity_requested'}, status=status.HTTP_400_BAD_REQUEST)
            request_obj.quantity_fulfilled = quantity_fulfilled
        
        request_obj.save()
        
        # If fulfilled, update resource inventory
        if new_status == 'fulfilled' and quantity_fulfilled:
            resource = request_obj.resource
            resource.available_quantity -= quantity_fulfilled
            if resource.available_quantity < 0:
                resource.available_quantity = 0
            resource.save()
            
            # Create inventory transaction
            ResourceInventoryTransaction.objects.create(
                resource=resource,
                transaction_type='fulfillment',
                quantity_delta=-quantity_fulfilled,
                reason=f'Fulfilled request {request_obj.id}',
                related_request=request_obj,
                created_by=request.user
            )
        
        # Create status history
        ResourceRequestStatusHistory.objects.create(
            request=request_obj,
            previous_status=previous_status,
            new_status=new_status,
            changed_by=request.user,
            note=note
        )
        
        return Response({
            'message': 'Resource request status updated successfully',
            'request_id': request_obj.id,
            'previous_status': previous_status,
            'new_status': new_status
        })
        
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def pending_resource_requests(request):
    """
    Get all pending resource requests
    """
    requests = ResourceRequest.objects.filter(status='pending').order_by('-priority', 'needed_by')
    
    request_list = []
    for req in requests:
        request_list.append({
            'id': req.id,
            'camp_name': req.camp.name,
            'resource_name': req.resource.name,
            'quantity_requested': float(req.quantity_requested),
            'priority': req.priority,
            'needed_by': req.needed_by.isoformat(),
            'reason': req.reason
        })
    
    return Response({'pending_requests': request_list})


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def urgent_resource_requests(request):
    """
    Get all urgent resource requests
    """
    requests = ResourceRequest.objects.filter(
        priority='urgent',
        status='pending'
    ).order_by('needed_by')
    
    request_list = []
    for req in requests:
        request_list.append({
            'id': req.id,
            'camp_name': req.camp.name,
            'resource_name': req.resource.name,
            'quantity_requested': float(req.quantity_requested),
            'needed_by': req.needed_by.isoformat(),
            'reason': req.reason
        })
    
    return Response({'urgent_requests': request_list})


# ========================================
# INVENTORY TRANSACTION VIEWS
# ========================================

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def list_inventory_transactions(request):
    """
    List all inventory transactions with optional filtering
    """
    transactions = ResourceInventoryTransaction.objects.all()
    
    # Filter by resource
    resource_id = request.GET.get('resource_id')
    if resource_id:
        transactions = transactions.filter(resource_id=resource_id)
    
    # Filter by transaction type
    transaction_type = request.GET.get('transaction_type')
    if transaction_type:
        transactions = transactions.filter(transaction_type=transaction_type)
    
    transactions = transactions.order_by('-created_at')
    
    transaction_list = []
    for t in transactions:
        transaction_list.append({
            'id': t.id,
            'resource_id': t.resource.id,
            'resource_name': t.resource.name,
            'transaction_type': t.transaction_type,
            'quantity_delta': float(t.quantity_delta),
            'reason': t.reason,
            'related_request_id': t.related_request.id if t.related_request else None,
            'created_by': t.created_by.username if t.created_by else None,
            'created_at': t.created_at.isoformat()
        })
    
    return Response({'inventory_transactions': transaction_list})
