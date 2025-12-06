from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.contrib.auth import get_user_model, authenticate
from django.conf import settings
from rest_framework.decorators import api_view, permission_classes, action
from rest_framework.permissions import IsAuthenticated, IsAdminUser
from rest_framework.response import Response
from rest_framework import status, viewsets, permissions
from rest_framework.views import APIView
from django.db.models import Q, Count, Sum, Avg
from django.utils import timezone
from datetime import timedelta
import json

from users.models import User, Volunteer, Victim, CampAdmin, VolunteerSkill
from relief.models import Resource, ResourceRequest, ResourceInventoryTransaction
from operations.models import (
    Donation,
    DonationItem,
    DonationAcknowledgment,
    HelpRequest,
    TaskAssignment,
    Transport,
    TransportTrip,
)
from disasters.models import Disasters
from alerts.models import Alert, WeatherAlert
from shelters.models import Camp

from .serializers import (
    UserSerializer, VolunteerSerializer, VictimSerializer, CampAdminSerializer,
    DisasterSerializer, CampSerializer, AlertSerializer, WeatherAlertSerializer,
    ResourceSerializer, ResourceRequestSerializer, ResourceInventoryTransactionSerializer,
    DonationSerializer, DonationItemSerializer,
    DonationAcknowledgmentSerializer, HelpRequestSerializer, TaskAssignmentSerializer,
    TransportSerializer, TransportTripSerializer
)

User = get_user_model()


# ========================================
# AUTHENTICATION ENDPOINTS
# ========================================

@csrf_exempt
def test_api(request):
    return JsonResponse({"message": "API working!"})


@csrf_exempt
def register_user(request):
    if request.method == 'POST':
        try:
            data = json.loads(request.body)
            username = data.get('username')
            email = data.get('email')
            password = data.get('password')
            role = data.get('role', 'victim')

            if not username or not email or not password:
                return JsonResponse({"error": "All fields required"}, status=400)

            if User.objects.filter(username=username).exists():
                return JsonResponse({"error": "Username already exists"}, status=400)

            if User.objects.filter(email=email).exists():
                return JsonResponse({"error": "Email already exists"}, status=400)

            # Use create_user from CustomUserManager to properly handle password hashing
            user = User.objects.create_user(
                username=username,
                email=email,
                password=password,  # create_user will hash this automatically
                role=role
            )

            return JsonResponse({"message": "User registered successfully", "user_id": user.id}, status=201)

        except Exception as e:
            import traceback
            # Return more detailed error for debugging
            error_detail = str(e)
            if settings.DEBUG:
                error_detail += f"\n{traceback.format_exc()}"
            return JsonResponse({"error": error_detail}, status=500)

    return JsonResponse({"error": "Only POST allowed"}, status=405)


@csrf_exempt
def login_user(request):
    if request.method == "POST":
        try:
            data = json.loads(request.body)
            username = data.get('username')
            password = data.get('password')

            if not username or not password:
                return JsonResponse({"error": "Username & password required"}, status=400)

            user = authenticate(username=username, password=password)
            if user is not None:
                return JsonResponse({
                    "message": "Login successful",
                    "user_id": user.id,
                    "username": user.username,
                    "role": user.role
                }, status=200)
            else:
                return JsonResponse({"error": "Invalid username or password"}, status=401)
        except Exception as e:
            return JsonResponse({"error": str(e)}, status=500)

    return JsonResponse({"error": "Only POST allowed"}, status=405)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def protected_route(request):
    return Response({
        "message": "You accessed a protected API!",
        "user": request.user.username,
        "role": request.user.role
    })


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def user_profile(request):
    """Return profile data based on user role"""
    user = request.user

    if user.role == "volunteer":
        try:
            volunteer = Volunteer.objects.get(user=user)
            serializer = VolunteerSerializer(volunteer)
            return Response(serializer.data)
        except Volunteer.DoesNotExist:
            # Return basic user profile if volunteer profile doesn't exist
            serializer = UserSerializer(user)
            data = serializer.data
            data['message'] = 'Volunteer profile not created yet. You can create it via /api/volunteers/ endpoint.'
            return Response(data)

    elif user.role == "victim":
        try:
            victim = Victim.objects.get(user=user)
            serializer = VictimSerializer(victim)
            return Response(serializer.data)
        except Victim.DoesNotExist:
            # Return basic user profile if victim profile doesn't exist
            serializer = UserSerializer(user)
            data = serializer.data
            data['message'] = 'Victim profile not created yet. You can create it via admin panel or API.'
            return Response(data)

    elif user.role == "camp_admin":
        try:
            camp_admin = CampAdmin.objects.get(user=user)
            serializer = CampAdminSerializer(camp_admin)
            return Response(serializer.data)
        except CampAdmin.DoesNotExist:
            # Return basic user profile if camp admin profile doesn't exist
            serializer = UserSerializer(user)
            data = serializer.data
            data['message'] = 'Camp admin profile not created yet. Contact administrator.'
            return Response(data)

    else:
        # For other roles (super_admin, donor) or no specific role, return basic user profile
        serializer = UserSerializer(user)
        return Response(serializer.data)


# ========================================
# VIEWSETS FOR ALL MODELS
# ========================================

class VolunteerViewSet(viewsets.ModelViewSet):
    queryset = Volunteer.objects.all()
    serializer_class = VolunteerSerializer
    permission_classes = [permissions.IsAuthenticated]

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

    @action(detail=False, methods=['get'])
    def available(self, request):
        """Get all available volunteers"""
        available_volunteers = self.queryset.filter(availability=True)
        serializer = self.get_serializer(available_volunteers, many=True)
        return Response(serializer.data)


class DisasterViewSet(viewsets.ModelViewSet):
    queryset = Disasters.objects.all()
    serializer_class = DisasterSerializer
    permission_classes = [permissions.IsAuthenticated]

    @action(detail=False, methods=['get'])
    def active(self, request):
        """Get all active disasters"""
        active_disasters = self.queryset.filter(status='active')
        serializer = self.get_serializer(active_disasters, many=True)
        return Response(serializer.data)


class CampViewSet(viewsets.ModelViewSet):
    queryset = Camp.objects.all()
    serializer_class = CampSerializer
    permission_classes = [permissions.IsAuthenticated]

    @action(detail=False, methods=['get'])
    def active(self, request):
        """Get all active camps"""
        active_camps = self.queryset.filter(status='active')
        serializer = self.get_serializer(active_camps, many=True)
        return Response(serializer.data)


class AlertViewSet(viewsets.ModelViewSet):
    queryset = Alert.objects.all()
    serializer_class = AlertSerializer
    permission_classes = [permissions.IsAuthenticated]

    @action(detail=False, methods=['get'])
    def active(self, request):
        """Get all active alerts"""
        active_alerts = self.queryset.filter(status='active')
        serializer = self.get_serializer(active_alerts, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def critical(self, request):
        """Get all critical alerts"""
        critical_alerts = self.queryset.filter(severity='critical', status='active')
        serializer = self.get_serializer(critical_alerts, many=True)
        return Response(serializer.data)


class ResourceViewSet(viewsets.ModelViewSet):
    queryset = Resource.objects.all()
    serializer_class = ResourceSerializer
    permission_classes = [permissions.IsAuthenticated]

    @action(detail=False, methods=['get'])
    def active(self, request):
        """Get all active resources"""
        active_resources = self.queryset.filter(is_active=True)
        serializer = self.get_serializer(active_resources, many=True)
        return Response(serializer.data)


class ResourceInventoryTransactionViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = ResourceInventoryTransaction.objects.all().order_by('-created_at')
    serializer_class = ResourceInventoryTransactionSerializer
    permission_classes = [permissions.IsAuthenticated]


class ResourceRequestViewSet(viewsets.ModelViewSet):
    queryset = ResourceRequest.objects.all()
    serializer_class = ResourceRequestSerializer
    permission_classes = [permissions.IsAuthenticated]

    @action(detail=False, methods=['get'])
    def pending(self, request):
        """Get all pending resource requests"""
        pending_requests = self.queryset.filter(status='pending')
        serializer = self.get_serializer(pending_requests, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def urgent(self, request):
        """Get all urgent resource requests"""
        urgent_requests = self.queryset.filter(priority='urgent', status='pending')
        serializer = self.get_serializer(urgent_requests, many=True)
        return Response(serializer.data)


class DonationViewSet(viewsets.ModelViewSet):
    queryset = Donation.objects.all()
    serializer_class = DonationSerializer
    permission_classes = [permissions.IsAuthenticated]

    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)

    @action(detail=True, methods=['post'])
    def acknowledge(self, request, pk=None):
        """Acknowledge a donation"""
        donation = self.get_object()
        acknowledgment_text = request.data.get('acknowledgment_text', 'Thank you for your donation!')
        
        acknowledgment, created = DonationAcknowledgment.objects.get_or_create(
            donation=donation,
            defaults={
                'acknowledgment_text': acknowledgment_text,
                'acknowledged_by': request.user
            }
        )
        
        serializer = DonationAcknowledgmentSerializer(acknowledgment)
        return Response(serializer.data)


class HelpRequestViewSet(viewsets.ModelViewSet):
    queryset = HelpRequest.objects.all()
    serializer_class = HelpRequestSerializer
    permission_classes = [permissions.IsAuthenticated]

    def perform_create(self, serializer):
        serializer.save(victim=self.request.user)

    @action(detail=False, methods=['get'])
    def pending(self, request):
        """Get all pending SOS requests"""
        pending_requests = self.queryset.filter(status='pending')
        serializer = self.get_serializer(pending_requests, many=True)
        return Response(serializer.data)

    @action(detail=True, methods=['post'])
    def assign_volunteer(self, request, pk=None):
        """Assign a volunteer to an SOS request"""
        help_request = self.get_object()
        volunteer_id = request.data.get('volunteer_id')
        
        try:
            volunteer = User.objects.get(id=volunteer_id, role='volunteer')
            task = TaskAssignment.objects.create(
                volunteer=volunteer,
                help_request=help_request,
                task_description=f"Help with: {help_request.description[:100]}"
            )
            help_request.status = 'in_progress'
            help_request.save()
            
            serializer = TaskAssignmentSerializer(task)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        except User.DoesNotExist:
            return Response({"error": "Volunteer not found"}, status=status.HTTP_404_NOT_FOUND)


class TaskAssignmentViewSet(viewsets.ModelViewSet):
    queryset = TaskAssignment.objects.all()
    serializer_class = TaskAssignmentSerializer
    permission_classes = [permissions.IsAuthenticated]

    @action(detail=False, methods=['get'])
    def my_tasks(self, request):
        """Get tasks assigned to current user"""
        if request.user.role == 'volunteer':
            tasks = self.queryset.filter(volunteer=request.user)
            serializer = self.get_serializer(tasks, many=True)
            return Response(serializer.data)
        return Response({"error": "Only volunteers can view their tasks"}, status=status.HTTP_403_FORBIDDEN)


class TransportViewSet(viewsets.ModelViewSet):
    queryset = Transport.objects.all()
    serializer_class = TransportSerializer
    permission_classes = [permissions.IsAuthenticated]

    @action(detail=False, methods=['get'])
    def available(self, request):
        """Get all available transports"""
        available_transports = self.queryset.filter(status='available')
        serializer = self.get_serializer(available_transports, many=True)
        return Response(serializer.data)


class TransportTripViewSet(viewsets.ModelViewSet):
    queryset = TransportTrip.objects.all()
    serializer_class = TransportTripSerializer
    permission_classes = [permissions.IsAuthenticated]

    @action(detail=False, methods=['get'])
    def upcoming(self, request):
        """Get scheduled or en route trips."""
        trips = self.queryset.filter(status__in=['scheduled', 'en_route']).order_by('departure_time')
        serializer = self.get_serializer(trips, many=True)
        return Response(serializer.data)


class WeatherAlertViewSet(viewsets.ModelViewSet):
    queryset = WeatherAlert.objects.all()
    serializer_class = WeatherAlertSerializer
    permission_classes = [permissions.IsAuthenticated]

    def perform_create(self, serializer):
        serializer.save(issued_by=self.request.user)

    @action(detail=False, methods=['get'])
    def active(self, request):
        """Get all active weather alerts"""
        active_alerts = self.queryset.filter(status__in=['forecast', 'active', 'warning'])
        serializer = self.get_serializer(active_alerts, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def high_risk(self, request):
        """Get all high/extreme risk weather alerts"""
        high_risk_alerts = self.queryset.filter(risk_level__in=['high', 'extreme'], status__in=['forecast', 'active', 'warning'])
        serializer = self.get_serializer(high_risk_alerts, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def by_type(self, request):
        """Get weather alerts filtered by weather type"""
        weather_type = request.query_params.get('type', None)
        if weather_type:
            alerts = self.queryset.filter(weather_type=weather_type)
            serializer = self.get_serializer(alerts, many=True)
            return Response(serializer.data)
        return Response({"error": "Please provide 'type' query parameter"}, status=status.HTTP_400_BAD_REQUEST)


# ========================================
# ADMIN DASHBOARD ENDPOINTS
# ========================================

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def admin_dashboard(request):
    """Comprehensive dashboard for admins"""
    if request.user.role not in ['super_admin', 'camp_admin']:
        return Response({"error": "Access denied. Admin role required."}, status=status.HTTP_403_FORBIDDEN)

    # Statistics
    stats = {
        "users": {
            "total": User.objects.count(),
            "volunteers": User.objects.filter(role='volunteer').count(),
            "victims": User.objects.filter(role='victim').count(),
            "admins": User.objects.filter(role__in=['super_admin', 'camp_admin']).count(),
        },
        "disasters": {
            "total": Disasters.objects.count(),
            "active": Disasters.objects.filter(status='active').count(),
            "critical": Disasters.objects.filter(severity='critical', status='active').count(),
        },
        "camps": {
            "total": Camp.objects.count(),
            "active": Camp.objects.filter(status='active').count(),
            "capacity_used": Camp.objects.aggregate(Sum('capacity'))['capacity__sum'] or 0,
        },
        "resources": {
            "total": Resource.objects.count(),
            "active": Resource.objects.filter(is_active=True).count(),
            "pending_requests": ResourceRequest.objects.filter(status='pending').count(),
            "urgent_requests": ResourceRequest.objects.filter(priority='urgent', status='pending').count(),
        },
        "donations": {
            "total": Donation.objects.count(),
            "this_month": Donation.objects.filter(
                donation_date__gte=timezone.now().replace(day=1)
            ).count(),
            "total_items": DonationItem.objects.count(),
        },
        "sos_requests": {
            "total": HelpRequest.objects.count(),
            "pending": HelpRequest.objects.filter(status='pending').count(),
            "in_progress": HelpRequest.objects.filter(status='in_progress').count(),
            "resolved": HelpRequest.objects.filter(status='resolved').count(),
        },
        "alerts": {
            "total": Alert.objects.count(),
            "active": Alert.objects.filter(status='active').count(),
            "critical": Alert.objects.filter(severity='critical', status='active').count(),
        },
        "weather_alerts": {
            "total": WeatherAlert.objects.count(),
            "active": WeatherAlert.objects.filter(status__in=['forecast', 'active', 'warning']).count(),
            "high_risk": WeatherAlert.objects.filter(risk_level__in=['high', 'extreme']).count(),
        },
        "tasks": {
            "total": TaskAssignment.objects.count(),
            "assigned": TaskAssignment.objects.filter(status='assigned').count(),
            "in_progress": TaskAssignment.objects.filter(status='in_progress').count(),
            "completed": TaskAssignment.objects.filter(status='completed').count(),
        },
    }

    return Response(stats)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def resource_analytics(request):
    """Analytics for resource management"""
    if request.user.role not in ['super_admin', 'camp_admin']:
        return Response({"error": "Access denied"}, status=status.HTTP_403_FORBIDDEN)

    analytics = {
        "resource_distribution": list(
            Resource.objects.values('category').annotate(count=Count('id'))
        ),
        "requests_by_priority": list(
            ResourceRequest.objects.values('priority').annotate(count=Count('id'))
        ),
        "requests_by_status": list(
            ResourceRequest.objects.values('status').annotate(count=Count('id'))
        ),
        "most_requested_resources": list(
            ResourceRequest.objects.values('resource__name', 'resource__category')
            .annotate(total_requests=Count('id'), total_quantity=Sum('quantity_requested'))
            .order_by('-total_requests')[:10]
        ),
    }

    return Response(analytics)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def donation_matching(request):
    """Smart donation matching - match donations with resource requests"""
    if request.user.role not in ['super_admin', 'camp_admin']:
        return Response({"error": "Access denied"}, status=status.HTTP_403_FORBIDDEN)

    # Get pending resource requests
    pending_requests = ResourceRequest.objects.filter(status='pending').select_related('resource')
    
    # Get recent donations with items
    recent_donations = Donation.objects.filter(
        donation_date__gte=timezone.now() - timedelta(days=30)
    ).prefetch_related('items__resource')
    
    matches = []
    
    for request in pending_requests:
        needed_resource = request.resource
        needed_quantity = request.quantity_requested - request.quantity_fulfilled
        
        # Find matching donations
        for donation in recent_donations:
            for item in donation.items.all():
                if item.resource == needed_resource and item.quantity > 0:
                    match_quantity = min(item.quantity, needed_quantity)
                    matches.append({
                        "request_id": request.id,
                        "camp": request.camp.name,
                        "resource": needed_resource.name,
                        "needed_quantity": float(needed_quantity),
                        "donation_id": donation.id,
                        "donor": donation.donor_name,
                        "available_quantity": float(item.quantity),
                        "match_quantity": float(match_quantity),
                        "priority": request.priority,
                    })
    
    return Response({"matches": matches})


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def volunteer_coordination(request):
    """Volunteer and team coordination data"""
    if request.user.role not in ['super_admin', 'camp_admin']:
        return Response({"error": "Access denied"}, status=status.HTTP_403_FORBIDDEN)

    coordination_data = {
        "available_volunteers": Volunteer.objects.filter(availability=True).count(),
        "volunteers_by_skill": list(
            VolunteerSkill.objects.values('skill')
            .annotate(count=Count('volunteer'))
            .order_by('-count')
        ),
        "active_tasks": TaskAssignment.objects.filter(
            status__in=['assigned', 'in_progress']
        ).count(),
        "volunteer_task_distribution": list(
            TaskAssignment.objects.values('volunteer__user__username')
            .annotate(task_count=Count('id'))
            .order_by('-task_count')[:10]
        ),
        "task_status_breakdown": list(
            TaskAssignment.objects.values('status').annotate(count=Count('id'))
        ),
    }

    return Response(coordination_data)


# ========================================
# SYSTEM STATUS & SUMMARY ENDPOINT
# ========================================

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def system_summary(request):
    """Get a summary of all features and their status"""
    summary = {
        "features": {
            "smart_resource_management": {
                "status": "✅ Complete",
                "endpoints": [
                    "GET/POST /api/resources/",
                    "GET/POST /api/resource-requests/",
                    "GET /api/resource-requests/pending/",
                    "GET /api/resource-requests/urgent/",
                    "GET /api/resource-inventory/",
                    "GET /api/admin/resource-analytics/"
                ]
            },
            "donation_matching_management": {
                "status": "✅ Complete",
                "endpoints": [
                    "GET/POST /api/donations/",
                    "POST /api/donations/{id}/acknowledge/",
                    "GET /api/admin/donation-matching/"
                ]
            },
            "volunteer_team_coordination": {
                "status": "✅ Complete",
                "endpoints": [
                    "GET/POST /api/volunteers/",
                    "GET/POST /api/tasks/",
                    "GET /api/tasks/my_tasks/",
                    "GET /api/admin/volunteer-coordination/"
                ]
            },
            "sos_request_panel": {
                "status": "✅ Complete",
                "endpoints": [
                    "GET/POST /api/sos-requests/",
                    "GET /api/sos-requests/pending/",
                    "POST /api/sos-requests/{id}/assign_volunteer/"
                ]
            },
            "weather_risk_alert": {
                "status": "✅ Complete",
                "endpoints": [
                    "GET/POST /api/weather-alerts/",
                    "GET /api/weather-alerts/active/",
                    "GET /api/weather-alerts/high_risk/",
                    "GET /api/weather-alerts/by_type/?type={type}"
                ]
            },
            "transport_trip_management": {
                "status": "✅ Complete",
                "endpoints": [
                    "GET/POST /api/transports/",
                    "GET/POST /api/transport-trips/",
                    "GET /api/transport-trips/upcoming/"
                ]
            },
            "audit_logging": {
                "status": "✅ Complete",
                "endpoints": [
                    "GET /api/resource-inventory/",
                    "GET /api/resource-requests/{id}/ (status_history)",
                    "GET /api/sos-requests/{id}/ (status_history)",
                    "GET /api/tasks/{id}/ (status_history)",
                    "GET /api/alerts/{id}/ (status_history)",
                    "GET /api/weather-alerts/{id}/ (status_history)"
                ]
            },
            "admin_dashboard": {
                "status": "✅ Complete",
                "endpoints": [
                    "GET /api/admin/dashboard/",
                    "GET /api/admin/resource-analytics/",
                    "GET /api/admin/donation-matching/",
                    "GET /api/admin/volunteer-coordination/"
                ]
            }
        },
        "authentication": {
            "status": "✅ Complete",
            "endpoints": [
                "POST /api/register/",
                "POST /api/login/",
                "POST /api/token/",
                "POST /api/token/refresh/",
                "GET /api/user/profile/"
            ]
        },
        "additional_features": {
            "disasters": "GET/POST /api/disasters/",
            "camps": "GET/POST /api/camps/",
            "alerts": "GET/POST /api/alerts/",
            "transports": "GET/POST /api/transports/"
        }
    }
    return Response(summary)
