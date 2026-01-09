from django.shortcuts import render, get_object_or_404
from django.http import JsonResponse
from django.views.decorators.http import require_http_methods
from django.views.decorators.csrf import csrf_exempt
from django.contrib.auth.decorators import login_required
from django.db.models import Q, Count
from django.utils import timezone
from datetime import timedelta
import json

from .models import Alert, AlertStatusHistory, WeatherAlert, WeatherAlertStatusHistory
from disasters.models import Disasters
from users.models import User


# ========================================
# ALERT MANAGEMENT VIEWS
# ========================================

@login_required
@require_http_methods(["GET"])
def list_alerts(request):
    """
    List all alerts with optional filtering
    """
    alerts = Alert.objects.all()
    
    # Filter by status
    status_filter = request.GET.get('status')
    if status_filter:
        alerts = alerts.filter(status=status_filter)
    
    # Filter by severity
    severity_filter = request.GET.get('severity')
    if severity_filter:
        alerts = alerts.filter(severity=severity_filter)
    
    # Filter by disaster
    disaster_id = request.GET.get('disaster_id')
    if disaster_id:
        alerts = alerts.filter(Disasters_id=disaster_id)
    
    alerts = alerts.order_by('-issued_at')
    
    alert_list = []
    for alert in alerts:
        alert_list.append({
            'id': alert.id,
            'disaster_id': alert.Disasters.id,
            'disaster_name': alert.Disasters.name,
            'title': alert.title,
            'description': alert.description,
            'severity': alert.severity,
            'status': alert.status,
            'issued_at': alert.issued_at.isoformat(),
            'resolved_at': alert.resolved_at.isoformat() if alert.resolved_at else None
        })
    
    return JsonResponse({'alerts': alert_list}, safe=False)


@login_required
@require_http_methods(["GET"])
def get_alert(request, alert_id):
    """
    Get a specific alert by ID
    """
    alert = get_object_or_404(Alert, id=alert_id)
    
    return JsonResponse({
        'id': alert.id,
        'disaster_id': alert.Disasters.id,
        'disaster_name': alert.Disasters.name,
        'title': alert.title,
        'description': alert.description,
        'severity': alert.severity,
        'status': alert.status,
        'issued_at': alert.issued_at.isoformat(),
        'resolved_at': alert.resolved_at.isoformat() if alert.resolved_at else None,
        'status_history': [
            {
                'previous_status': h.previous_status,
                'new_status': h.new_status,
                'changed_by': h.changed_by.username if h.changed_by else None,
                'note': h.note,
                'changed_at': h.changed_at.isoformat()
            }
            for h in alert.status_history.all()
        ]
    })


@login_required
@require_http_methods(["POST"])
@csrf_exempt
def create_alert(request):
    """
    Create a new alert (admin only)
    """
    if request.user.role not in ['super_admin', 'camp_admin']:
        return JsonResponse({'error': 'Unauthorized. Admin role required.'}, status=403)
    
    try:
        data = json.loads(request.body)
        disaster_id = data.get('disaster_id')
        title = data.get('title')
        description = data.get('description')
        severity = data.get('severity', 'medium')
        
        if not disaster_id or not title or not description:
            return JsonResponse({'error': 'disaster_id, title, and description are required'}, status=400)
        
        disaster = get_object_or_404(Disasters, id=disaster_id)
        
        # Validate severity
        valid_severities = ['low', 'medium', 'high', 'critical']
        if severity not in valid_severities:
            return JsonResponse({'error': f'Invalid severity. Must be one of: {valid_severities}'}, status=400)
        
        alert = Alert.objects.create(
            Disasters=disaster,
            title=title,
            description=description,
            severity=severity,
            status='active'
        )
        
        # Create status history entry
        AlertStatusHistory.objects.create(
            alert=alert,
            previous_status='active',  # Initial status
            new_status='active',
            changed_by=request.user,
            note='Alert created'
        )
        
        return JsonResponse({
            'message': 'Alert created successfully',
            'alert_id': alert.id,
            'issued_at': alert.issued_at.isoformat()
        }, status=201)
        
    except json.JSONDecodeError:
        return JsonResponse({'error': 'Invalid JSON'}, status=400)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)


@login_required
@require_http_methods(["PUT", "PATCH"])
@csrf_exempt
def update_alert_status(request, alert_id):
    """
    Update alert status (admin only)
    """
    if request.user.role not in ['super_admin', 'camp_admin']:
        return JsonResponse({'error': 'Unauthorized. Admin role required.'}, status=403)
    
    try:
        data = json.loads(request.body)
        new_status = data.get('status')
        note = data.get('note', '')
        
        if not new_status:
            return JsonResponse({'error': 'status is required'}, status=400)
        
        alert = get_object_or_404(Alert, id=alert_id)
        previous_status = alert.status
        
        # Validate status
        valid_statuses = ['active', 'resolved', 'cancelled']
        if new_status not in valid_statuses:
            return JsonResponse({'error': f'Invalid status. Must be one of: {valid_statuses}'}, status=400)
        
        alert.status = new_status
        if new_status == 'resolved' and not alert.resolved_at:
            alert.resolved_at = timezone.now()
        alert.save()
        
        # Create status history entry
        AlertStatusHistory.objects.create(
            alert=alert,
            previous_status=previous_status,
            new_status=new_status,
            changed_by=request.user,
            note=note
        )
        
        return JsonResponse({
            'message': 'Alert status updated successfully',
            'alert_id': alert.id,
            'previous_status': previous_status,
            'new_status': new_status
        })
        
    except json.JSONDecodeError:
        return JsonResponse({'error': 'Invalid JSON'}, status=400)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)


@login_required
@require_http_methods(["GET"])
def active_alerts(request):
    """
    Get all active alerts
    """
    alerts = Alert.objects.filter(status='active').order_by('-issued_at', '-severity')
    
    alert_list = []
    for alert in alerts:
        alert_list.append({
            'id': alert.id,
            'disaster_id': alert.Disasters.id,
            'disaster_name': alert.Disasters.name,
            'title': alert.title,
            'description': alert.description,
            'severity': alert.severity,
            'issued_at': alert.issued_at.isoformat()
        })
    
    return JsonResponse({'active_alerts': alert_list}, safe=False)


@login_required
@require_http_methods(["GET"])
def critical_alerts(request):
    """
    Get all critical alerts
    """
    alerts = Alert.objects.filter(severity='critical', status='active').order_by('-issued_at')
    
    alert_list = []
    for alert in alerts:
        alert_list.append({
            'id': alert.id,
            'disaster_id': alert.Disasters.id,
            'disaster_name': alert.Disasters.name,
            'title': alert.title,
            'description': alert.description,
            'issued_at': alert.issued_at.isoformat()
        })
    
    return JsonResponse({'critical_alerts': alert_list}, safe=False)


# ========================================
# WEATHER ALERT MANAGEMENT VIEWS
# ========================================

@login_required
@require_http_methods(["GET"])
def list_weather_alerts(request):
    """
    List all weather alerts with optional filtering
    """
    alerts = WeatherAlert.objects.all()
    
    # Filter by status
    status_filter = request.GET.get('status')
    if status_filter:
        alerts = alerts.filter(status=status_filter)
    
    # Filter by risk level
    risk_level = request.GET.get('risk_level')
    if risk_level:
        alerts = alerts.filter(risk_level=risk_level)
    
    # Filter by weather type
    weather_type = request.GET.get('weather_type')
    if weather_type:
        alerts = alerts.filter(weather_type=weather_type)
    
    alerts = alerts.order_by('-forecast_date', '-risk_level')
    
    alert_list = []
    for alert in alerts:
        alert_list.append({
            'id': alert.id,
            'weather_type': alert.weather_type,
            'risk_level': alert.risk_level,
            'status': alert.status,
            'location': alert.location,
            'latitude': float(alert.latitude) if alert.latitude else None,
            'longitude': float(alert.longitude) if alert.longitude else None,
            'title': alert.title,
            'description': alert.description,
            'forecast_date': alert.forecast_date.isoformat(),
            'expected_severity': alert.expected_severity,
            'affected_radius_km': float(alert.affected_radius_km) if alert.affected_radius_km else None,
            'wind_speed_kmh': float(alert.wind_speed_kmh) if alert.wind_speed_kmh else None,
            'rainfall_mm': float(alert.rainfall_mm) if alert.rainfall_mm else None,
            'temperature_celsius': float(alert.temperature_celsius) if alert.temperature_celsius else None,
            'issued_by': alert.issued_by.username if alert.issued_by else None,
            'issued_at': alert.issued_at.isoformat(),
            'expires_at': alert.expires_at.isoformat() if alert.expires_at else None,
            'related_disaster_id': alert.related_disaster.id if alert.related_disaster else None
        })
    
    return JsonResponse({'weather_alerts': alert_list}, safe=False)


@login_required
@require_http_methods(["POST"])
@csrf_exempt
def create_weather_alert(request):
    """
    Create a new weather alert (admin only)
    """
    if request.user.role not in ['super_admin', 'camp_admin']:
        return JsonResponse({'error': 'Unauthorized. Admin role required.'}, status=403)
    
    try:
        data = json.loads(request.body)
        
        weather_type = data.get('weather_type')
        risk_level = data.get('risk_level', 'moderate')
        status = data.get('status', 'forecast')
        location = data.get('location')
        title = data.get('title')
        description = data.get('description')
        forecast_date = data.get('forecast_date')
        
        if not weather_type or not location or not title or not description or not forecast_date:
            return JsonResponse({
                'error': 'weather_type, location, title, description, and forecast_date are required'
            }, status=400)
        
        # Validate choices
        valid_weather_types = ['hurricane', 'flood', 'drought', 'storm', 'tornado', 'heatwave', 'coldwave', 'tsunami', 'other']
        valid_risk_levels = ['low', 'moderate', 'high', 'extreme']
        valid_statuses = ['forecast', 'active', 'warning', 'expired']
        
        if weather_type not in valid_weather_types:
            return JsonResponse({'error': f'Invalid weather_type. Must be one of: {valid_weather_types}'}, status=400)
        if risk_level not in valid_risk_levels:
            return JsonResponse({'error': f'Invalid risk_level. Must be one of: {valid_risk_levels}'}, status=400)
        if status not in valid_statuses:
            return JsonResponse({'error': f'Invalid status. Must be one of: {valid_statuses}'}, status=400)
        
        # Parse forecast_date
        from django.utils.dateparse import parse_datetime
        forecast_datetime = parse_datetime(forecast_date)
        if not forecast_datetime:
            return JsonResponse({'error': 'Invalid forecast_date format. Use ISO format.'}, status=400)
        
        alert = WeatherAlert.objects.create(
            weather_type=weather_type,
            risk_level=risk_level,
            status=status,
            location=location,
            latitude=data.get('latitude'),
            longitude=data.get('longitude'),
            title=title,
            description=description,
            forecast_date=forecast_datetime,
            expected_severity=data.get('expected_severity', 'medium'),
            affected_radius_km=data.get('affected_radius_km'),
            wind_speed_kmh=data.get('wind_speed_kmh'),
            rainfall_mm=data.get('rainfall_mm'),
            temperature_celsius=data.get('temperature_celsius'),
            issued_by=request.user,
            expires_at=parse_datetime(data.get('expires_at')) if data.get('expires_at') else None,
            related_disaster_id=data.get('related_disaster_id')
        )
        
        # Create status history entry
        WeatherAlertStatusHistory.objects.create(
            weather_alert=alert,
            previous_status=status,
            new_status=status,
            changed_by=request.user,
            note='Weather alert created'
        )
        
        return JsonResponse({
            'message': 'Weather alert created successfully',
            'alert_id': alert.id,
            'issued_at': alert.issued_at.isoformat()
        }, status=201)
        
    except json.JSONDecodeError:
        return JsonResponse({'error': 'Invalid JSON'}, status=400)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)


@login_required
@require_http_methods(["GET"])
def active_weather_alerts(request):
    """
    Get all active weather alerts (forecast, active, warning)
    """
    alerts = WeatherAlert.objects.filter(
        status__in=['forecast', 'active', 'warning']
    ).order_by('-forecast_date', '-risk_level')
    
    alert_list = []
    for alert in alerts:
        alert_list.append({
            'id': alert.id,
            'weather_type': alert.weather_type,
            'risk_level': alert.risk_level,
            'status': alert.status,
            'location': alert.location,
            'title': alert.title,
            'description': alert.description,
            'forecast_date': alert.forecast_date.isoformat(),
            'expected_severity': alert.expected_severity
        })
    
    return JsonResponse({'active_weather_alerts': alert_list}, safe=False)


@login_required
@require_http_methods(["GET"])
def high_risk_weather_alerts(request):
    """
    Get all high/extreme risk weather alerts
    """
    alerts = WeatherAlert.objects.filter(
        risk_level__in=['high', 'extreme'],
        status__in=['forecast', 'active', 'warning']
    ).order_by('-forecast_date', '-risk_level')
    
    alert_list = []
    for alert in alerts:
        alert_list.append({
            'id': alert.id,
            'weather_type': alert.weather_type,
            'risk_level': alert.risk_level,
            'status': alert.status,
            'location': alert.location,
            'title': alert.title,
            'description': alert.description,
            'forecast_date': alert.forecast_date.isoformat()
        })
    
    return JsonResponse({'high_risk_weather_alerts': alert_list}, safe=False)


@login_required
@require_http_methods(["PUT", "PATCH"])
@csrf_exempt
def update_weather_alert_status(request, alert_id):
    """
    Update weather alert status (admin only)
    """
    if request.user.role not in ['super_admin', 'camp_admin']:
        return JsonResponse({'error': 'Unauthorized. Admin role required.'}, status=403)
    
    try:
        data = json.loads(request.body)
        new_status = data.get('status')
        note = data.get('note', '')
        
        if not new_status:
            return JsonResponse({'error': 'status is required'}, status=400)
        
        alert = get_object_or_404(WeatherAlert, id=alert_id)
        previous_status = alert.status
        
        # Validate status
        valid_statuses = ['forecast', 'active', 'warning', 'expired']
        if new_status not in valid_statuses:
            return JsonResponse({'error': f'Invalid status. Must be one of: {valid_statuses}'}, status=400)
        
        alert.status = new_status
        alert.save()
        
        # Create status history entry
        WeatherAlertStatusHistory.objects.create(
            weather_alert=alert,
            previous_status=previous_status,
            new_status=new_status,
            changed_by=request.user,
            note=note
        )
        
        return JsonResponse({
            'message': 'Weather alert status updated successfully',
            'alert_id': alert.id,
            'previous_status': previous_status,
            'new_status': new_status
        })
        
    except json.JSONDecodeError:
        return JsonResponse({'error': 'Invalid JSON'}, status=400)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)
