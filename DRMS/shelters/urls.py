from django.urls import path
from . import views

urlpatterns = [
    path('camps/', views.list_camps, name='list_camps'),
    path('camps/<int:camp_id>/', views.get_camp, name='get_camp'),
    path('camps/create/', views.create_camp, name='create_camp'),
    path('camps/<int:camp_id>/update/', views.update_camp, name='update_camp'),
    path('camps/active/', views.active_camps, name='active_camps'),
    path('camps/statistics/', views.camp_statistics, name='camp_statistics'),
    path('camps/capacity-report/', views.camp_capacity_report, name='camp_capacity_report'),
]

