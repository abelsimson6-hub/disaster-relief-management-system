from django.shortcuts import render, get_object_or_404
from django.http import JsonResponse
from django.views.decorators.http import require_http_methods
from django.views.decorators.csrf import csrf_exempt
from django.contrib.auth.decorators import login_required
from django.db.models import Q, Count, Sum, Avg
from django.utils import timezone
from datetime import timedelta
import json

from .models import Disasters
from shelters.models import Camp
from alerts.models import Alert
from operations.models import HelpRequest


# ========================================
# DISASTER MANAGEMENT VIEWS
# ========================================

@login_required
@require_http_methods(["GET"])
def list_disasters(request):
    """
    List all disasters with optional filtering
    """
    disasters = Disasters.objects.all()
    
    # Filter by status
    status_filter = request.GET.get('status')
    if status_filter:
        disasters = disasters.filter(status=status_filter)
    
    # Filter by disaster type
    disaster_type = request.GET.get('disaster_type')
    if disaster_type:
        disasters = disasters.filter(disaster_type=disaster_type)
    
    # Filter by severity
    severity = request.GET.get('severity')
    if severity:
        disasters = disasters.filter(severity=severity)
    
    disasters = disasters.order_by('-start_date')
    
    disaster_list = []
    for disaster in disasters:
        disaster_list.append({
            'id': disaster.id,
            'name': disaster.name,
            'disaster_type': disaster.disaster_type,
            'severity': disaster.severity,
            'status': disaster.status,
            'location': disaster.location,
            'latitude': float(disaster.latitude) if disaster.latitude else None,
            'longitude': float(disaster.longitude) if disaster.longitude else None,
            'description': disaster.description,
            'start_date': disaster.start_date.isoformat(),
            'end_date': disaster.end_date.isoformat() if disaster.end_date else None,
            'estimated_damage': float(disaster.estimated_damage) if disaster.estimated_damage else None,
            'affected_areas': disaster.affected_areas,
            'affected_population_estimate': disaster.affected_population_estimate,
            'impact_radius_km': float(disaster.impact_radius_km) if disaster.impact_radius_km else None,
            'created_at': disaster.created_at.isoformat(),
            'updated_at': disaster.updated_at.isoformat()
        })
    
    return JsonResponse({'disasters': disaster_list}, safe=False)


@login_required
@require_http_methods(["GET"])
def get_disaster(request, disaster_id):
    """
    Get a specific disaster by ID with related information
    """
    disaster = get_object_or_404(Disasters, id=disaster_id)
    
    # Get related camps
    camps = Camp.objects.filter(disasters=disaster)
    camp_list = [{
        'id': camp.id,
        'name': camp.name,
        'camp_type': camp.camp_type,
        'status': camp.status,
        'location': camp.location,
        'capacity': camp.capacity
    } for camp in camps]
    
    # Get related alerts
    alerts = Alert.objects.filter(Disasters=disaster)
    alert_list = [{
        'id': alert.id,
        'title': alert.title,
        'severity': alert.severity,
        'status': alert.status,
        'issued_at': alert.issued_at.isoformat()
    } for alert in alerts]
    
    # Get help requests
    help_requests = HelpRequest.objects.filter(disasters=disaster)
    help_request_list = [{
        'id': req.id,
        'description': req.description,
        'status': req.status,
        'requested_at': req.requested_at.isoformat()
    } for req in help_requests]
    
    return JsonResponse({
        'id': disaster.id,
        'name': disaster.name,
        'disaster_type': disaster.disaster_type,
        'severity': disaster.severity,
        'status': disaster.status,
        'location': disaster.location,
        'latitude': float(disaster.latitude) if disaster.latitude else None,
        'longitude': float(disaster.longitude) if disaster.longitude else None,
        'description': disaster.description,
        'start_date': disaster.start_date.isoformat(),
        'end_date': disaster.end_date.isoformat() if disaster.end_date else None,
        'estimated_damage': float(disaster.estimated_damage) if disaster.estimated_damage else None,
        'affected_areas': disaster.affected_areas,
        'affected_population_estimate': disaster.affected_population_estimate,
        'impact_radius_km': float(disaster.impact_radius_km) if disaster.impact_radius_km else None,
        'impact_area_description': disaster.impact_area_description,
        'created_at': disaster.created_at.isoformat(),
        'updated_at': disaster.updated_at.isoformat(),
        'related_camps': camp_list,
        'related_alerts': alert_list,
        'help_requests': help_request_list,
        'statistics': {
            'total_camps': camps.count(),
            'active_camps': camps.filter(status='active').count(),
            'total_alerts': alerts.count(),
            'active_alerts': alerts.filter(status='active').count(),
            'total_help_requests': help_requests.count(),
            'pending_help_requests': help_requests.filter(status='pending').count()
        }
    })


@login_required
@require_http_methods(["POST"])
@csrf_exempt
def create_disaster(request):
    """
    Create a new disaster (admin only)
    """
    if request.user.role not in ['super_admin', 'camp_admin']:
        return JsonResponse({'error': 'Unauthorized. Admin role required.'}, status=403)
    
    try:
        data = json.loads(request.body)
        
        name = data.get('name')
        disaster_type = data.get('disaster_type')
        severity = data.get('severity')
        location = data.get('location')
        description = data.get('description')
        start_date = data.get('start_date')
        
        if not name or not disaster_type or not severity or not location or not description or not start_date:
            return JsonResponse({
                'error': 'name, disaster_type, severity, location, description, and start_date are required'
            }, status=400)
        
        # Validate choices
        valid_types = ['earthquake', 'flood', 'hurricane', 'tsunami', 'fire', 'landslide', 'drought', 'other']
        valid_severities = ['low', 'medium', 'high', 'critical']
        
        if disaster_type not in valid_types:
            return JsonResponse({'error': f'Invalid disaster_type. Must be one of: {valid_types}'}, status=400)
        if severity not in valid_severities:
            return JsonResponse({'error': f'Invalid severity. Must be one of: {valid_severities}'}, status=400)
        
        # Parse start_date
        from django.utils.dateparse import parse_datetime
        start_datetime = parse_datetime(start_date)
        if not start_datetime:
            return JsonResponse({'error': 'Invalid start_date format. Use ISO format.'}, status=400)
        
        disaster = Disasters.objects.create(
            name=name,
            disaster_type=disaster_type,
            severity=severity,
            status='active',
            location=location,
            latitude=data.get('latitude'),
            longitude=data.get('longitude'),
            description=description,
            start_date=start_datetime,
            end_date=parse_datetime(data.get('end_date')) if data.get('end_date') else None,
            estimated_damage=data.get('estimated_damage'),
            affected_areas=data.get('affected_areas', ''),
            affected_population_estimate=data.get('affected_population_estimate'),
            impact_radius_km=data.get('impact_radius_km'),
            impact_area_description=data.get('impact_area_description', ''),
            geojson_boundary=data.get('geojson_boundary', '')
        )
        
        return JsonResponse({
            'message': 'Disaster created successfully',
            'disaster_id': disaster.id,
            'created_at': disaster.created_at.isoformat()
        }, status=201)
        
    except json.JSONDecodeError:
        return JsonResponse({'error': 'Invalid JSON'}, status=400)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)


@login_required
@require_http_methods(["PUT", "PATCH"])
@csrf_exempt
def update_disaster(request, disaster_id):
    """
    Update a disaster (admin only)
    """
    if request.user.role not in ['super_admin', 'camp_admin']:
        return JsonResponse({'error': 'Unauthorized. Admin role required.'}, status=403)
    
    try:
        data = json.loads(request.body)
        disaster = get_object_or_404(Disasters, id=disaster_id)
        
        # Update fields if provided
        if 'name' in data:
            disaster.name = data['name']
        if 'disaster_type' in data:
            valid_types = ['earthquake', 'flood', 'hurricane', 'tsunami', 'fire', 'landslide', 'drought', 'other']
            if data['disaster_type'] not in valid_types:
                return JsonResponse({'error': f'Invalid disaster_type. Must be one of: {valid_types}'}, status=400)
            disaster.disaster_type = data['disaster_type']
        if 'severity' in data:
            valid_severities = ['low', 'medium', 'high', 'critical']
            if data['severity'] not in valid_severities:
                return JsonResponse({'error': f'Invalid severity. Must be one of: {valid_severities}'}, status=400)
            disaster.severity = data['severity']
        if 'status' in data:
            valid_statuses = ['active', 'contained', 'resolved']
            if data['status'] not in valid_statuses:
                return JsonResponse({'error': f'Invalid status. Must be one of: {valid_statuses}'}, status=400)
            disaster.status = data['status']
        if 'location' in data:
            disaster.location = data['location']
        if 'latitude' in data:
            disaster.latitude = data['latitude']
        if 'longitude' in data:
            disaster.longitude = data['longitude']
        if 'description' in data:
            disaster.description = data['description']
        if 'start_date' in data:
            from django.utils.dateparse import parse_datetime
            start_datetime = parse_datetime(data['start_date'])
            if start_datetime:
                disaster.start_date = start_datetime
        if 'end_date' in data:
            from django.utils.dateparse import parse_datetime
            end_datetime = parse_datetime(data['end_date'])
            disaster.end_date = end_datetime if end_datetime else None
        if 'estimated_damage' in data:
            disaster.estimated_damage = data['estimated_damage']
        if 'affected_areas' in data:
            disaster.affected_areas = data['affected_areas']
        if 'affected_population_estimate' in data:
            disaster.affected_population_estimate = data['affected_population_estimate']
        if 'impact_radius_km' in data:
            disaster.impact_radius_km = data['impact_radius_km']
        if 'impact_area_description' in data:
            disaster.impact_area_description = data['impact_area_description']
        
        disaster.save()
        
        return JsonResponse({
            'message': 'Disaster updated successfully',
            'disaster_id': disaster.id,
            'updated_at': disaster.updated_at.isoformat()
        })
        
    except json.JSONDecodeError:
        return JsonResponse({'error': 'Invalid JSON'}, status=400)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)


@login_required
@require_http_methods(["GET"])
def active_disasters(request):
    """
    Get all active disasters
    """
    disasters = Disasters.objects.filter(status='active').order_by('-start_date', '-severity')
    
    disaster_list = []
    for disaster in disasters:
        disaster_list.append({
            'id': disaster.id,
            'name': disaster.name,
            'disaster_type': disaster.disaster_type,
            'severity': disaster.severity,
            'location': disaster.location,
            'start_date': disaster.start_date.isoformat(),
            'affected_population_estimate': disaster.affected_population_estimate
        })
    
    return JsonResponse({'active_disasters': disaster_list}, safe=False)


@login_required
@require_http_methods(["GET"])
def critical_disasters(request):
    """
    Get all critical disasters
    """
    disasters = Disasters.objects.filter(severity='critical', status='active').order_by('-start_date')
    
    disaster_list = []
    for disaster in disasters:
        disaster_list.append({
            'id': disaster.id,
            'name': disaster.name,
            'disaster_type': disaster.disaster_type,
            'location': disaster.location,
            'start_date': disaster.start_date.isoformat(),
            'affected_population_estimate': disaster.affected_population_estimate
        })
    
    return JsonResponse({'critical_disasters': disaster_list}, safe=False)


@login_required
@require_http_methods(["GET"])
def disaster_statistics(request):
    """
    Get disaster statistics
    """
    stats = {
        'total_disasters': Disasters.objects.count(),
        'active_disasters': Disasters.objects.filter(status='active').count(),
        'resolved_disasters': Disasters.objects.filter(status='resolved').count(),
        'contained_disasters': Disasters.objects.filter(status='contained').count(),
        'disasters_by_type': list(
            Disasters.objects.values('disaster_type')
            .annotate(count=Count('id'))
            .order_by('-count')
        ),
        'disasters_by_severity': list(
            Disasters.objects.values('severity')
            .annotate(count=Count('id'))
            .order_by('-count')
        ),
        'total_affected_population': Disasters.objects.aggregate(
            total=Sum('affected_population_estimate')
        )['total'] or 0,
        'total_estimated_damage': float(
            Disasters.objects.aggregate(total=Sum('estimated_damage'))['total'] or 0
        )
    }
    
    return JsonResponse(stats)
