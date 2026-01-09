from django.urls import path
from . import views

urlpatterns = [
    path('alerts/', views.list_alerts, name='list_alerts'),
    path('alerts/<int:alert_id>/', views.get_alert, name='get_alert'),
    path('alerts/create/', views.create_alert, name='create_alert'),
    path('alerts/<int:alert_id>/status/', views.update_alert_status, name='update_alert_status'),
    path('alerts/active/', views.active_alerts, name='active_alerts'),
    path('alerts/critical/', views.critical_alerts, name='critical_alerts'),
    path('weather-alerts/', views.list_weather_alerts, name='list_weather_alerts'),
    path('weather-alerts/create/', views.create_weather_alert, name='create_weather_alert'),
    path('weather-alerts/active/', views.active_weather_alerts, name='active_weather_alerts'),
    path('weather-alerts/high-risk/', views.high_risk_weather_alerts, name='high_risk_weather_alerts'),
    path('weather-alerts/<int:alert_id>/status/', views.update_weather_alert_status, name='update_weather_alert_status'),
]

