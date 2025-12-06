from django.contrib import admin
from .models import User, Volunteer, VolunteerSkill, Victim, CampAdmin


# -----------------------------
# User Admin
# -----------------------------
@admin.register(User)
class UserAdmin(admin.ModelAdmin):
    list_display = ('username', 'email', 'role', 'is_staff', 'is_active', 'date_joined')
    list_filter = ('role', 'is_staff', 'is_active')
    search_fields = ('username', 'email', 'phone')
    ordering = ('username',)
    readonly_fields = ('created_at', 'updated_at', 'date_joined', 'last_login')
    
    # Make role field editable in admin
    fieldsets = (
        (None, {'fields': ('username', 'password')}),
        ('Personal info', {'fields': ('first_name', 'last_name', 'email', 'phone', 'address')}),
        ('Permissions', {'fields': ('is_active', 'is_staff', 'is_superuser', 'role', 'groups', 'user_permissions')}),
        ('Important dates', {'fields': ('last_login', 'date_joined', 'created_at', 'updated_at')}),
    )


# -----------------------------
# Volunteer Admin
# -----------------------------
@admin.register(Volunteer)
class VolunteerAdmin(admin.ModelAdmin):
    list_display = ('user', 'availability', 'join_date')
    list_filter = ('availability',)
    search_fields = ('user__username',)
    ordering = ('-join_date',)


# -----------------------------
# VolunteerSkill Admin
# -----------------------------
@admin.register(VolunteerSkill)
class VolunteerSkillAdmin(admin.ModelAdmin):
    list_display = ('volunteer', 'skill', 'proficiency')
    list_filter = ('proficiency',)
    search_fields = ('volunteer__user__username', 'skill')
    ordering = ('volunteer',)


# -----------------------------
# Victim Admin
# -----------------------------
@admin.register(Victim)
class VictimAdmin(admin.ModelAdmin):
    list_display = ('user', 'age', 'family_members', 'emergency_contact', 'registration_date')
    list_filter = ('family_members',)
    search_fields = ('user__username', 'emergency_contact')
    ordering = ('-registration_date',)


# -----------------------------
# CampAdmin Admin
# -----------------------------
@admin.register(CampAdmin)
class CampAdminAdmin(admin.ModelAdmin):
    list_display = ('user', 'camp', 'assigned_at')
    list_filter = ('camp',)
    search_fields = ('user__username', 'camp__name')
    ordering = ('-assigned_at',)
