from django.contrib import admin
from .models import (
    Donation,
    DonationItem,
    DonationAcknowledgment,
    Transport,
    HelpRequest,
    TaskAssignment,
)

# ------------------------
# Inline: Show DonationItems inside Donation
# ------------------------
class DonationItemInline(admin.TabularInline):
    model = DonationItem
    extra = 1  # shows one empty field by default

# ------------------------
# Donation Admin
# ------------------------
@admin.register(Donation)
class DonationAdmin(admin.ModelAdmin):
    list_display = ('id', 'donor_name', 'donor_type', 'contact_email', 'donation_date', 'created_by')
    list_filter = ('donor_type', 'donation_date')
    search_fields = ('donor_name', 'contact_email', 'contact_phone')
    inlines = [DonationItemInline]
    readonly_fields = ('donation_date',)

# ------------------------
# Donation Acknowledgment Admin
# ------------------------
@admin.register(DonationAcknowledgment)
class DonationAcknowledgmentAdmin(admin.ModelAdmin):
    list_display = ('id', 'donation', 'acknowledged_by', 'acknowledged_at')
    search_fields = ('donation__donor_name', 'acknowledged_by__username')
    readonly_fields = ('acknowledged_at',)

# ------------------------
# Transport Admin
# ------------------------
@admin.register(Transport)
class TransportAdmin(admin.ModelAdmin):
    list_display = ('id', 'vehicle_number', 'transport_type', 'capacity', 'status', 'assigned_to_camp', 'last_service_date')
    list_filter = ('transport_type', 'status')
    search_fields = ('vehicle_number',)
    readonly_fields = ('created_at',)
    ordering = ('-created_at',)

# ------------------------
# Help Request Admin
# ------------------------
@admin.register(HelpRequest)
class HelpRequestAdmin(admin.ModelAdmin):
    list_display = ('id', 'victim', 'disasters', 'status', 'location', 'requested_at')
    list_filter = ('status', 'disasters')
    search_fields = ('victim__username', 'location', 'description')
    readonly_fields = ('requested_at',)
    ordering = ('-requested_at',)

# ------------------------
# Task Assignment Admin
# ------------------------
@admin.register(TaskAssignment)
class TaskAssignmentAdmin(admin.ModelAdmin):
    list_display = ('id', 'volunteer', 'task_description', 'status', 'assigned_at', 'help_request')
    list_filter = ('status',)
    search_fields = ('volunteer__username', 'task_description')
    readonly_fields = ('assigned_at',)
    ordering = ('-assigned_at',)
