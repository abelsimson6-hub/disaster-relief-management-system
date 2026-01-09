from django.urls import path
from . import views

urlpatterns = [
    # Donations
    path('donations/', views.list_donations, name='list_donations'),
    path('donations/create/', views.create_donation, name='create_donation'),
    path('donations/my-donations/', views.my_donations, name='my_donations'),
    path('donations/camp/<int:camp_id>/', views.camp_donations, name='camp_donations'),
    path('donations/<int:donation_id>/status/', views.update_donation_status, name='update_donation_status'),
    path('donations/<int:donation_id>/acknowledge/', views.acknowledge_donation, name='acknowledge_donation'),
    
    # Help Requests (SOS)
    path('help-requests/', views.list_help_requests, name='list_help_requests'),
    path('help-requests/create/', views.create_help_request, name='create_help_request'),
    path('help-requests/<int:request_id>/status/', views.update_help_request_status, name='update_help_request_status'),
    path('help-requests/<int:request_id>/assign-volunteer/', views.assign_volunteer_to_help_request, name='assign_volunteer_to_help_request'),
    
    # Task Assignments
    path('tasks/', views.list_task_assignments, name='list_task_assignments'),
    path('tasks/create/', views.create_task_assignment, name='create_task_assignment'),
    path('tasks/<int:task_id>/status/', views.update_task_status, name='update_task_status'),
    
    # Transport
    path('transports/', views.list_transports, name='list_transports'),
    path('transports/available/', views.available_transports, name='available_transports'),
    path('transport-trips/', views.list_transport_trips, name='list_transport_trips'),
]

