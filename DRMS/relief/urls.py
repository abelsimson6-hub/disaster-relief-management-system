from django.urls import path
from . import views

urlpatterns = [
    # Resources
    path('resources/', views.list_resources, name='list_resources'),
    path('resources/<int:resource_id>/', views.get_resource, name='get_resource'),
    path('resources/create/', views.create_resource, name='create_resource'),
    path('resources/<int:resource_id>/update/', views.update_resource, name='update_resource'),
    path('resources/<int:resource_id>/adjust-inventory/', views.adjust_inventory, name='adjust_inventory'),
    
    # Resource Requests
    path('resource-requests/', views.list_resource_requests, name='list_resource_requests'),
    path('resource-requests/create/', views.create_resource_request, name='create_resource_request'),
    path('resource-requests/<int:request_id>/status/', views.update_resource_request_status, name='update_resource_request_status'),
    path('resource-requests/pending/', views.pending_resource_requests, name='pending_resource_requests'),
    path('resource-requests/urgent/', views.urgent_resource_requests, name='urgent_resource_requests'),
    
    # Inventory Transactions
    path('inventory-transactions/', views.list_inventory_transactions, name='list_inventory_transactions'),
]

