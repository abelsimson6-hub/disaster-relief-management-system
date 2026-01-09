from django.urls import path
from . import views

urlpatterns = [
    path('disasters/', views.list_disasters, name='list_disasters'),
    path('disasters/<int:disaster_id>/', views.get_disaster, name='get_disaster'),
    path('disasters/create/', views.create_disaster, name='create_disaster'),
    path('disasters/<int:disaster_id>/update/', views.update_disaster, name='update_disaster'),
    path('disasters/active/', views.active_disasters, name='active_disasters'),
    path('disasters/critical/', views.critical_disasters, name='critical_disasters'),
    path('disasters/statistics/', views.disaster_statistics, name='disaster_statistics'),
]

