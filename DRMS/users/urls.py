from django.urls import path
from . import views

urlpatterns = [
    # User Management
    path('users/', views.list_users, name='list_users'),
    path('users/<int:user_id>/', views.get_user, name='get_user'),
    path('users/<int:user_id>/update/', views.update_user_profile, name='update_user_profile'),
    path('users/profile/', views.my_profile, name='my_profile'),
    
    # Volunteers
    path('volunteers/', views.list_volunteers, name='list_volunteers'),
    path('volunteers/profile/', views.create_volunteer_profile, name='create_volunteer_profile'),
    path('volunteers/available/', views.available_volunteers, name='available_volunteers'),
    path('volunteers/<int:volunteer_id>/tasks/', views.volunteer_tasks, name='volunteer_tasks'),
    
    # Victims
    path('victims/', views.list_victims, name='list_victims'),
    path('victims/profile/', views.create_victim_profile, name='create_victim_profile'),
    path('victims/high-priority/', views.high_priority_victims, name='high_priority_victims'),
    path('victims/<int:victim_id>/help-requests/', views.victim_help_requests, name='victim_help_requests'),
    
    # Camp Admin
    path('camp-admins/assign/', views.assign_camp_admin, name='assign_camp_admin'),
    
    # Statistics
    path('users/statistics/', views.user_statistics, name='user_statistics'),
]

