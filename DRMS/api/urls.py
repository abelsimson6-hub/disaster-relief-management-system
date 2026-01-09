from django.urls import path, include
from rest_framework import routers
from rest_framework_simplejwt.views import (
    TokenObtainPairView,
    TokenRefreshView,
)

from .views import (
    # Basic / utility
    test_api,
    register_user,
    protected_route,
    user_profile,
    system_summary,

    # ViewSets
    VolunteerViewSet,
    DisasterViewSet,
    CampViewSet,
    AlertViewSet,
    WeatherAlertViewSet,
    ResourceViewSet,
    ResourceInventoryTransactionViewSet,
    ResourceRequestViewSet,
    DonationViewSet,
    HelpRequestViewSet,
    TaskAssignmentViewSet,
    TransportViewSet,
    TransportTripViewSet,

    # Admin endpoints
    admin_dashboard,
    resource_analytics,
    donation_matching,
    volunteer_coordination,
)

# -------------------------
# Router configuration
# -------------------------
router = routers.DefaultRouter()
router.register(r'volunteers', VolunteerViewSet, basename='volunteer')
router.register(r'disasters', DisasterViewSet, basename='disaster')
router.register(r'camps', CampViewSet, basename='camp')
router.register(r'alerts', AlertViewSet, basename='alert')
router.register(r'weather-alerts', WeatherAlertViewSet, basename='weatheralert')
router.register(r'resources', ResourceViewSet, basename='resource')
router.register(r'resource-inventory', ResourceInventoryTransactionViewSet, basename='resourceinventory')
router.register(r'resource-requests', ResourceRequestViewSet, basename='resourcerequest')
router.register(r'donations', DonationViewSet, basename='donation')
router.register(r'sos-requests', HelpRequestViewSet, basename='helprequest')
router.register(r'tasks', TaskAssignmentViewSet, basename='taskassignment')
router.register(r'transports', TransportViewSet, basename='transport')
router.register(r'transport-trips', TransportTripViewSet, basename='transporttrip')

# -------------------------
# URL patterns
# -------------------------
urlpatterns = [
    # Health / test
    path('test/', test_api, name='test'),

    # System summary
    path('summary/', system_summary, name='system_summary'),

    # Authentication
    path('register/', register_user, name='register'),

    # JWT authentication (LOGIN)
    path('token/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),

    # Protected user routes
    path('protected/', protected_route, name='protected'),
    path('user/profile/', user_profile, name='user_profile'),

    # Admin dashboard
    path('admin/dashboard/', admin_dashboard, name='admin_dashboard'),
    path('admin/resource-analytics/', resource_analytics, name='resource_analytics'),
    path('admin/donation-matching/', donation_matching, name='donation_matching'),
    path('admin/volunteer-coordination/', volunteer_coordination, name='volunteer_coordination'),

    # API ViewSets
    path('', include(router.urls)),
]
