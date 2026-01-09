from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include('api.urls')),
    # App-specific endpoints
    path('api/', include('communication.urls')),
    path('api/', include('alerts.urls')),
    path('api/', include('disasters.urls')),
    path('api/', include('operations.urls')),
    path('api/', include('relief.urls')),
    path('api/', include('shelters.urls')),
    path('api/', include('users.urls')),
]
