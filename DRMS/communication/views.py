from django.shortcuts import render, get_object_or_404
from django.http import JsonResponse, HttpResponse
from django.views.decorators.http import require_http_methods
from django.views.decorators.csrf import csrf_exempt
from django.contrib.auth.decorators import login_required
from django.db.models import Q, Count
from django.utils import timezone
from datetime import timedelta
import json

from .models import Communication
from users.models import User


# ========================================
# MESSAGE MANAGEMENT VIEWS
# ========================================

@login_required
@require_http_methods(["GET"])
def list_messages(request):
    """
    List all messages for the current user (both sent and received)
    """
    user = request.user
    messages = Communication.objects.filter(
        Q(sender=user) | Q(receiver=user)
    ).order_by('-sent_at')
    
    message_list = []
    for msg in messages:
        message_list.append({
            'id': msg.id,
            'sender': msg.sender.username,
            'receiver': msg.receiver.username,
            'message_type': msg.message_type,
            'content': msg.content,
            'sent_at': msg.sent_at.isoformat(),
            'status': msg.status,
            'is_sent_by_me': msg.sender == user
        })
    
    return JsonResponse({'messages': message_list}, safe=False)


@login_required
@require_http_methods(["GET"])
def get_conversation(request, user_id):
    """
    Get conversation between current user and another user
    """
    current_user = request.user
    other_user = get_object_or_404(User, id=user_id)
    
    messages = Communication.objects.filter(
        (Q(sender=current_user) & Q(receiver=other_user)) |
        (Q(sender=other_user) & Q(receiver=current_user))
    ).order_by('sent_at')
    
    conversation = []
    for msg in messages:
        conversation.append({
            'id': msg.id,
            'sender': msg.sender.username,
            'sender_id': msg.sender.id,
            'message_type': msg.message_type,
            'content': msg.content,
            'sent_at': msg.sent_at.isoformat(),
            'status': msg.status
        })
    
    return JsonResponse({'conversation': conversation}, safe=False)


@login_required
@require_http_methods(["POST"])
@csrf_exempt
def send_message(request):
    """
    Send a message to another user
    """
    try:
        data = json.loads(request.body)
        receiver_id = data.get('receiver_id')
        content = data.get('content')
        message_type = data.get('message_type', 'text')
        
        if not receiver_id or not content:
            return JsonResponse({'error': 'receiver_id and content are required'}, status=400)
        
        receiver = get_object_or_404(User, id=receiver_id)
        sender = request.user
        
        # Validate message type
        valid_types = ['text', 'image', 'video', 'document']
        if message_type not in valid_types:
            return JsonResponse({'error': f'Invalid message_type. Must be one of: {valid_types}'}, status=400)
        
        message = Communication.objects.create(
            sender=sender,
            receiver=receiver,
            content=content,
            message_type=message_type,
            status='sent'
        )
        
        return JsonResponse({
            'message': 'Message sent successfully',
            'message_id': message.id,
            'sent_at': message.sent_at.isoformat()
        }, status=201)
        
    except json.JSONDecodeError:
        return JsonResponse({'error': 'Invalid JSON'}, status=400)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)


@login_required
@require_http_methods(["GET"])
def get_message(request, message_id):
    """
    Get a specific message by ID
    """
    message = get_object_or_404(Communication, id=message_id)
    
    # Check if user is sender or receiver
    if message.sender != request.user and message.receiver != request.user:
        return JsonResponse({'error': 'Unauthorized'}, status=403)
    
    # Mark as delivered if receiver is viewing
    if message.receiver == request.user and message.status == 'sent':
        message.status = 'delivered'
        message.save()
    
    return JsonResponse({
        'id': message.id,
        'sender': message.sender.username,
        'sender_id': message.sender.id,
        'receiver': message.receiver.username,
        'receiver_id': message.receiver.id,
        'message_type': message.message_type,
        'content': message.content,
        'sent_at': message.sent_at.isoformat(),
        'status': message.status
    })


@login_required
@require_http_methods(["PUT", "PATCH"])
@csrf_exempt
def mark_message_read(request, message_id):
    """
    Mark a message as read
    """
    message = get_object_or_404(Communication, id=message_id)
    
    # Only receiver can mark as read
    if message.receiver != request.user:
        return JsonResponse({'error': 'Only receiver can mark message as read'}, status=403)
    
    message.status = 'read'
    message.save()
    
    return JsonResponse({
        'message': 'Message marked as read',
        'message_id': message.id,
        'status': message.status
    })


@login_required
@require_http_methods(["DELETE"])
@csrf_exempt
def delete_message(request, message_id):
    """
    Delete a message (only sender can delete)
    """
    message = get_object_or_404(Communication, id=message_id)
    
    if message.sender != request.user:
        return JsonResponse({'error': 'Only sender can delete message'}, status=403)
    
    message.delete()
    
    return JsonResponse({'message': 'Message deleted successfully'}, status=200)


# ========================================
# MESSAGE STATISTICS & HELPERS
# ========================================

@login_required
@require_http_methods(["GET"])
def message_statistics(request):
    """
    Get message statistics for the current user
    """
    user = request.user
    
    sent_messages = Communication.objects.filter(sender=user)
    received_messages = Communication.objects.filter(receiver=user)
    
    stats = {
        'total_sent': sent_messages.count(),
        'total_received': received_messages.count(),
        'unread_count': received_messages.filter(status__in=['sent', 'delivered']).count(),
        'read_count': received_messages.filter(status='read').count(),
        'messages_by_type': list(
            Communication.objects.filter(
                Q(sender=user) | Q(receiver=user)
            ).values('message_type').annotate(count=Count('id'))
        ),
        'recent_contacts': list(
            Communication.objects.filter(
                Q(sender=user) | Q(receiver=user)
            ).values('receiver__username', 'sender__username').distinct()[:10]
        )
    }
    
    return JsonResponse(stats)


@login_required
@require_http_methods(["GET"])
def unread_messages(request):
    """
    Get all unread messages for the current user
    """
    user = request.user
    unread = Communication.objects.filter(
        receiver=user,
        status__in=['sent', 'delivered']
    ).order_by('-sent_at')
    
    unread_list = []
    for msg in unread:
        unread_list.append({
            'id': msg.id,
            'sender': msg.sender.username,
            'sender_id': msg.sender.id,
            'message_type': msg.message_type,
            'content': msg.content[:100],  # Preview
            'sent_at': msg.sent_at.isoformat(),
            'status': msg.status
        })
    
    return JsonResponse({'unread_messages': unread_list, 'count': len(unread_list)}, safe=False)


@login_required
@require_http_methods(["POST"])
@csrf_exempt
def mark_all_read(request):
    """
    Mark all messages as read for the current user
    """
    user = request.user
    updated = Communication.objects.filter(
        receiver=user,
        status__in=['sent', 'delivered']
    ).update(status='read')
    
    return JsonResponse({
        'message': f'Marked {updated} messages as read'
    })


# ========================================
# BULK OPERATIONS
# ========================================

@login_required
@require_http_methods(["POST"])
@csrf_exempt
def send_bulk_message(request):
    """
    Send a message to multiple users (for admins)
    """
    if request.user.role not in ['super_admin', 'camp_admin']:
        return JsonResponse({'error': 'Unauthorized. Admin role required.'}, status=403)
    
    try:
        data = json.loads(request.body)
        receiver_ids = data.get('receiver_ids', [])
        content = data.get('content')
        message_type = data.get('message_type', 'text')
        
        if not receiver_ids or not content:
            return JsonResponse({'error': 'receiver_ids and content are required'}, status=400)
        
        if not isinstance(receiver_ids, list):
            return JsonResponse({'error': 'receiver_ids must be a list'}, status=400)
        
        sender = request.user
        created_messages = []
        
        for receiver_id in receiver_ids:
            try:
                receiver = User.objects.get(id=receiver_id)
                message = Communication.objects.create(
                    sender=sender,
                    receiver=receiver,
                    content=content,
                    message_type=message_type,
                    status='sent'
                )
                created_messages.append(message.id)
            except User.DoesNotExist:
                continue
        
        return JsonResponse({
            'message': f'Successfully sent {len(created_messages)} messages',
            'message_ids': created_messages
        }, status=201)
        
    except json.JSONDecodeError:
        return JsonResponse({'error': 'Invalid JSON'}, status=400)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)
