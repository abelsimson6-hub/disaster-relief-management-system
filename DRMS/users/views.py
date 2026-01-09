from django.shortcuts import render, get_object_or_404
from django.http import JsonResponse
from django.views.decorators.http import require_http_methods
from django.views.decorators.csrf import csrf_exempt
from django.contrib.auth.decorators import login_required
from django.contrib.auth import authenticate, login, logout
from django.db.models import Q, Count, Sum, Avg
from django.utils import timezone
from datetime import timedelta
import json

from .models import User, Volunteer, Victim, CampAdmin, VolunteerSkill
from operations.models import TaskAssignment, HelpRequest
from shelters.models import Camp


# ========================================
# USER MANAGEMENT VIEWS
# ========================================

@login_required
@require_http_methods(["GET"])
def list_users(request):
    """
    List all users with optional filtering (admin only)
    """
    if request.user.role not in ['super_admin', 'camp_admin']:
        return JsonResponse({'error': 'Unauthorized. Admin role required.'}, status=403)
    
    users = User.objects.all()
    
    # Filter by role
    role_filter = request.GET.get('role')
    if role_filter:
        users = users.filter(role=role_filter)
    
    # Filter by active status
    is_active = request.GET.get('is_active')
    if is_active is not None:
        users = users.filter(is_active=is_active.lower() == 'true')
    
    users = users.order_by('username')
    
    user_list = []
    for user in users:
        user_list.append({
            'id': user.id,
            'username': user.username,
            'email': user.email,
            'role': user.role,
            'phone': user.phone,
            'address': user.address,
            'is_active': user.is_active,
            'is_staff': user.is_staff,
            'date_joined': user.date_joined.isoformat(),
            'created_at': user.created_at.isoformat()
        })
    
    return JsonResponse({'users': user_list}, safe=False)


@login_required
@require_http_methods(["GET"])
def get_user(request, user_id):
    """
    Get a specific user by ID
    """
    user = get_object_or_404(User, id=user_id)
    
    # Check permissions - users can view their own profile, admins can view any
    if request.user.id != user_id and request.user.role not in ['super_admin', 'camp_admin']:
        return JsonResponse({'error': 'Unauthorized'}, status=403)
    
    user_data = {
        'id': user.id,
        'username': user.username,
        'email': user.email,
        'role': user.role,
        'phone': user.phone,
        'address': user.address,
        'is_active': user.is_active,
        'is_staff': user.is_staff,
        'date_joined': user.date_joined.isoformat(),
        'created_at': user.created_at.isoformat(),
        'updated_at': user.updated_at.isoformat()
    }
    
    # Add role-specific information
    if user.role == 'volunteer':
        try:
            volunteer = Volunteer.objects.get(user=user)
            user_data['volunteer'] = {
                'availability': volunteer.availability,
                'experience': volunteer.experience,
                'join_date': volunteer.join_date.isoformat(),
                'skills': [{
                    'skill': skill.skill,
                    'proficiency': skill.proficiency
                } for skill in volunteer.skills.all()]
            }
        except Volunteer.DoesNotExist:
            pass
    
    elif user.role == 'victim':
        try:
            victim = Victim.objects.get(user=user)
            user_data['victim'] = {
                'age': victim.age,
                'family_members': victim.family_members,
                'emergency_contact': victim.emergency_contact,
                'special_needs': victim.special_needs,
                'medical_conditions': victim.medical_conditions,
                'priority_level': victim.priority_level,
                'is_high_risk': victim.is_high_risk,
                'emergency_supplies_needed': victim.emergency_supplies_needed,
                'registration_date': victim.registration_date.isoformat()
            }
        except Victim.DoesNotExist:
            pass
    
    elif user.role == 'camp_admin':
        try:
            camp_admin = CampAdmin.objects.get(user=user)
            user_data['camp_admin'] = {
                'camp_id': camp_admin.camp.id,
                'camp_name': camp_admin.camp.name,
                'assigned_at': camp_admin.assigned_at.isoformat()
            }
        except CampAdmin.DoesNotExist:
            pass
    
    return JsonResponse(user_data)


@login_required
@require_http_methods(["PUT", "PATCH"])
@csrf_exempt
def update_user_profile(request, user_id):
    """
    Update user profile (users can update their own, admins can update any)
    Includes location updates
    """
    user = get_object_or_404(User, id=user_id)
    
    # Check permissions
    if request.user.id != user_id and request.user.role not in ['super_admin', 'camp_admin']:
        return JsonResponse({'error': 'Unauthorized'}, status=403)
    
    try:
        data = json.loads(request.body)
        
        # Only admins can change role and is_active
        if request.user.role in ['super_admin', 'camp_admin']:
            if 'role' in data:
                valid_roles = ['super_admin', 'camp_admin', 'volunteer', 'victim', 'donor']
                if data['role'] not in valid_roles:
                    return JsonResponse({'error': f'Invalid role. Must be one of: {valid_roles}'}, status=400)
                user.role = data['role']
            if 'is_active' in data:
                user.is_active = data['is_active']
        
        # Users can update their own basic info
        if 'email' in data:
            user.email = data['email']
        if 'phone' in data:
            user.phone = data['phone']
        if 'address' in data:
            user.address = data['address']
        
        # Location updates
        location_updated = False
        if 'current_location' in data:
            user.current_location = data['current_location']
            location_updated = True
        if 'latitude' in data:
            user.latitude = data['latitude']
            location_updated = True
        if 'longitude' in data:
            user.longitude = data['longitude']
            location_updated = True
        
        if location_updated:
            from django.utils import timezone
            user.location_updated_at = timezone.now()
        
        user.save()
        
        return JsonResponse({
            'message': 'User profile updated successfully',
            'user_id': user.id,
            'updated_at': user.updated_at.isoformat(),
            'location_updated': location_updated
        })
        
    except json.JSONDecodeError:
        return JsonResponse({'error': 'Invalid JSON'}, status=400)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)


@login_required
@require_http_methods(["GET"])
def my_profile(request):
    """
    Get current user's profile
    """
    return get_user(request, request.user.id)


# ========================================
# VOLUNTEER MANAGEMENT VIEWS
# ========================================

@login_required
@require_http_methods(["GET"])
def list_volunteers(request):
    """
    List all volunteers
    """
    volunteers = Volunteer.objects.all()
    
    # Filter by availability
    availability = request.GET.get('availability')
    if availability is not None:
        volunteers = volunteers.filter(availability=availability.lower() == 'true')
    
    volunteer_list = []
    for volunteer in volunteers:
        volunteer_list.append({
            'id': volunteer.id,
            'user_id': volunteer.user.id,
            'username': volunteer.user.username,
            'email': volunteer.user.email,
            'phone': volunteer.user.phone,
            'availability': volunteer.availability,
            'experience': volunteer.experience,
            'join_date': volunteer.join_date.isoformat(),
            'skills': [{
                'skill': skill.skill,
                'proficiency': skill.proficiency
            } for skill in volunteer.skills.all()]
        })
    
    return JsonResponse({'volunteers': volunteer_list}, safe=False)


@login_required
@require_http_methods(["POST"])
@csrf_exempt
def create_volunteer_profile(request):
    """
    Create or update volunteer profile
    """
    if request.user.role != 'volunteer':
        return JsonResponse({'error': 'Only volunteers can create volunteer profiles'}, status=403)
    
    try:
        data = json.loads(request.body)
        
        volunteer, created = Volunteer.objects.get_or_create(
            user=request.user,
            defaults={
                'availability': data.get('availability', True),
                'experience': data.get('experience', '')
            }
        )
        
        if not created:
            # Update existing profile
            if 'availability' in data:
                volunteer.availability = data['availability']
            if 'experience' in data:
                volunteer.experience = data['experience']
            volunteer.save()
        
        # Add skills if provided
        skills = data.get('skills', [])
        for skill_data in skills:
            skill_name = skill_data.get('skill')
            proficiency = skill_data.get('proficiency', 'beginner')
            
            if skill_name:
                valid_proficiencies = ['beginner', 'intermediate', 'expert']
                if proficiency not in valid_proficiencies:
                    proficiency = 'beginner'
                
                VolunteerSkill.objects.update_or_create(
                    volunteer=volunteer,
                    skill=skill_name,
                    defaults={'proficiency': proficiency}
                )
        
        return JsonResponse({
            'message': 'Volunteer profile created/updated successfully',
            'volunteer_id': volunteer.id,
            'created': created
        }, status=201 if created else 200)
        
    except json.JSONDecodeError:
        return JsonResponse({'error': 'Invalid JSON'}, status=400)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)


@login_required
@require_http_methods(["GET"])
def available_volunteers(request):
    """
    Get all available volunteers
    """
    volunteers = Volunteer.objects.filter(availability=True)
    
    volunteer_list = []
    for volunteer in volunteers:
        volunteer_list.append({
            'id': volunteer.id,
            'user_id': volunteer.user.id,
            'username': volunteer.user.username,
            'skills': [skill.skill for skill in volunteer.skills.all()]
        })
    
    return JsonResponse({'available_volunteers': volunteer_list}, safe=False)


@login_required
@require_http_methods(["GET"])
def volunteer_tasks(request, volunteer_id):
    """
    Get tasks assigned to a volunteer
    """
    volunteer_user = get_object_or_404(User, id=volunteer_id, role='volunteer')
    
    # Check permissions
    if request.user.id != volunteer_id and request.user.role not in ['super_admin', 'camp_admin']:
        return JsonResponse({'error': 'Unauthorized'}, status=403)
    
    tasks = TaskAssignment.objects.filter(volunteer=volunteer_user).order_by('-assigned_at')
    
    task_list = []
    for task in tasks:
        task_list.append({
            'id': task.id,
            'task_description': task.task_description,
            'help_request_id': task.help_request.id if task.help_request else None,
            'status': task.status,
            'assigned_at': task.assigned_at.isoformat()
        })
    
    return JsonResponse({'tasks': task_list}, safe=False)


# ========================================
# VICTIM MANAGEMENT VIEWS
# ========================================

@login_required
@require_http_methods(["GET"])
def list_victims(request):
    """
    List all victims (admin only)
    """
    if request.user.role not in ['super_admin', 'camp_admin']:
        return JsonResponse({'error': 'Unauthorized. Admin role required.'}, status=403)
    
    victims = Victim.objects.all().order_by('-registration_date')
    
    # Filter by priority
    priority = request.GET.get('priority')
    if priority:
        victims = victims.filter(priority_level=priority)
    
    # Filter by high risk
    high_risk = request.GET.get('high_risk')
    if high_risk is not None:
        victims = victims.filter(is_high_risk=high_risk.lower() == 'true')
    
    victim_list = []
    for victim in victims:
        victim_list.append({
            'id': victim.id,
            'user_id': victim.user.id,
            'username': victim.user.username,
            'email': victim.user.email,
            'phone': victim.user.phone,
            'age': victim.age,
            'family_members': victim.family_members,
            'emergency_contact': victim.emergency_contact,
            'special_needs': victim.special_needs,
            'medical_conditions': victim.medical_conditions,
            'priority_level': victim.priority_level,
            'is_high_risk': victim.is_high_risk,
            'emergency_supplies_needed': victim.emergency_supplies_needed,
            'registration_date': victim.registration_date.isoformat()
        })
    
    return JsonResponse({'victims': victim_list}, safe=False)


@login_required
@require_http_methods(["POST"])
@csrf_exempt
def create_victim_profile(request):
    """
    Create or update victim profile
    """
    if request.user.role != 'victim':
        return JsonResponse({'error': 'Only victims can create victim profiles'}, status=403)
    
    try:
        data = json.loads(request.body)
        
        victim, created = Victim.objects.get_or_create(
            user=request.user,
            defaults={
                'age': data.get('age'),
                'family_members': data.get('family_members', 1),
                'emergency_contact': data.get('emergency_contact', ''),
                'special_needs': data.get('special_needs', ''),
                'medical_conditions': data.get('medical_conditions', ''),
                'priority_level': data.get('priority_level', 'medium'),
                'is_high_risk': data.get('is_high_risk', False),
                'emergency_supplies_needed': data.get('emergency_supplies_needed', '')
            }
        )
        
        if not created:
            # Update existing profile
            if 'age' in data:
                victim.age = data['age']
            if 'family_members' in data:
                victim.family_members = data['family_members']
            if 'emergency_contact' in data:
                victim.emergency_contact = data['emergency_contact']
            if 'special_needs' in data:
                victim.special_needs = data['special_needs']
            if 'medical_conditions' in data:
                victim.medical_conditions = data['medical_conditions']
            if 'priority_level' in data:
                valid_priorities = ['low', 'medium', 'high', 'critical']
                if data['priority_level'] in valid_priorities:
                    victim.priority_level = data['priority_level']
            if 'is_high_risk' in data:
                victim.is_high_risk = data['is_high_risk']
            if 'emergency_supplies_needed' in data:
                victim.emergency_supplies_needed = data['emergency_supplies_needed']
            victim.save()
        
        return JsonResponse({
            'message': 'Victim profile created/updated successfully',
            'victim_id': victim.id,
            'created': created
        }, status=201 if created else 200)
        
    except json.JSONDecodeError:
        return JsonResponse({'error': 'Invalid JSON'}, status=400)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)


@login_required
@require_http_methods(["GET"])
def high_priority_victims(request):
    """
    Get high priority victims (admin only)
    """
    if request.user.role not in ['super_admin', 'camp_admin']:
        return JsonResponse({'error': 'Unauthorized. Admin role required.'}, status=403)
    
    victims = Victim.objects.filter(
        Q(priority_level__in=['high', 'critical']) | Q(is_high_risk=True)
    ).order_by('-priority_level', '-registration_date')
    
    victim_list = []
    for victim in victims:
        victim_list.append({
            'id': victim.id,
            'user_id': victim.user.id,
            'username': victim.user.username,
            'phone': victim.user.phone,
            'priority_level': victim.priority_level,
            'is_high_risk': victim.is_high_risk,
            'medical_conditions': victim.medical_conditions,
            'special_needs': victim.special_needs
        })
    
    return JsonResponse({'high_priority_victims': victim_list}, safe=False)


@login_required
@require_http_methods(["GET"])
def victim_help_requests(request, victim_id):
    """
    Get help requests made by a victim
    """
    victim_user = get_object_or_404(User, id=victim_id, role='victim')
    
    # Check permissions
    if request.user.id != victim_id and request.user.role not in ['super_admin', 'camp_admin']:
        return JsonResponse({'error': 'Unauthorized'}, status=403)
    
    help_requests = HelpRequest.objects.filter(victim=victim_user).order_by('-requested_at')
    
    request_list = []
    for req in help_requests:
        request_list.append({
            'id': req.id,
            'disaster_name': req.disasters.name,
            'description': req.description,
            'location': req.location,
            'status': req.status,
            'requested_at': req.requested_at.isoformat()
        })
    
    return JsonResponse({'help_requests': request_list}, safe=False)


# ========================================
# CAMP ADMIN MANAGEMENT VIEWS
# ========================================

@login_required
@require_http_methods(["POST"])
@csrf_exempt
def assign_camp_admin(request):
    """
    Assign a camp admin to a camp (super admin only)
    """
    if request.user.role != 'super_admin':
        return JsonResponse({'error': 'Unauthorized. Super admin role required.'}, status=403)
    
    try:
        data = json.loads(request.body)
        user_id = data.get('user_id')
        camp_id = data.get('camp_id')
        
        if not user_id or not camp_id:
            return JsonResponse({'error': 'user_id and camp_id are required'}, status=400)
        
        user = get_object_or_404(User, id=user_id)
        if user.role != 'camp_admin':
            return JsonResponse({'error': 'User must have camp_admin role'}, status=400)
        
        camp = get_object_or_404(Camp, id=camp_id)
        
        camp_admin, created = CampAdmin.objects.get_or_create(
            user=user,
            camp=camp
        )
        
        return JsonResponse({
            'message': 'Camp admin assigned successfully',
            'camp_admin_id': camp_admin.id,
            'created': created
        }, status=201 if created else 200)
        
    except json.JSONDecodeError:
        return JsonResponse({'error': 'Invalid JSON'}, status=400)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)


# ========================================
# USER STATISTICS
# ========================================

@login_required
@require_http_methods(["GET"])
def user_statistics(request):
    """
    Get user statistics (admin only)
    """
    if request.user.role not in ['super_admin', 'camp_admin']:
        return JsonResponse({'error': 'Unauthorized. Admin role required.'}, status=403)
    
    stats = {
        'total_users': User.objects.count(),
        'users_by_role': list(
            User.objects.values('role')
            .annotate(count=Count('id'))
            .order_by('-count')
        ),
        'active_users': User.objects.filter(is_active=True).count(),
        'total_volunteers': Volunteer.objects.count(),
        'available_volunteers': Volunteer.objects.filter(availability=True).count(),
        'total_victims': Victim.objects.count(),
        'high_priority_victims': Victim.objects.filter(
            Q(priority_level__in=['high', 'critical']) | Q(is_high_risk=True)
        ).count(),
        'total_camp_admins': CampAdmin.objects.count(),
        'users_by_month': list(
            User.objects.extra(
                select={'month': "DATE_TRUNC('month', created_at)"}
            ).values('month')
            .annotate(count=Count('id'))
            .order_by('month')
        ) if hasattr(User.objects.model._meta.db_table, 'created_at') else []
    }
    
    return JsonResponse(stats)
