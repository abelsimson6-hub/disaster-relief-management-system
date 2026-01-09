from django.urls import path
from . import views

urlpatterns = [
    path('messages/', views.list_messages, name='list_messages'),
    path('messages/conversation/<int:user_id>/', views.get_conversation, name='get_conversation'),
    path('messages/send/', views.send_message, name='send_message'),
    path('messages/<int:message_id>/', views.get_message, name='get_message'),
    path('messages/<int:message_id>/read/', views.mark_message_read, name='mark_message_read'),
    path('messages/<int:message_id>/delete/', views.delete_message, name='delete_message'),
    path('messages/statistics/', views.message_statistics, name='message_statistics'),
    path('messages/unread/', views.unread_messages, name='unread_messages'),
    path('messages/mark-all-read/', views.mark_all_read, name='mark_all_read'),
    path('messages/bulk-send/', views.send_bulk_message, name='send_bulk_message'),
]

