from rest_framework import serializers
from users.models import User, Volunteer, Victim, CampAdmin, VolunteerSkill
from relief.models import Resource, ResourceRequest, ResourceInventoryTransaction, ResourceRequestStatusHistory
from operations.models import (
    Donation,
    DonationItem,
    DonationAcknowledgment,
    HelpRequest,
    TaskAssignment,
    Transport,
    HelpRequestStatusHistory,
    TaskAssignmentStatusHistory,
    TransportTrip,
)
from disasters.models import Disasters
from alerts.models import Alert, WeatherAlert, AlertStatusHistory, WeatherAlertStatusHistory
from shelters.models import Camp


# -----------------------------
# User Serializers
# -----------------------------
class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ["id", "username", "email", "role", "phone", "address", "created_at"]
        read_only_fields = ["id", "created_at"]


class VolunteerSkillSerializer(serializers.ModelSerializer):
    class Meta:
        model = VolunteerSkill
        fields = ["id", "skill", "proficiency"]


class VolunteerSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    skills = VolunteerSkillSerializer(many=True, read_only=True)

    class Meta:
        model = Volunteer
        fields = ["id", "user", "availability", "experience", "join_date", "skills"]


class VictimSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)

    class Meta:
        model = Victim
        fields = [
            "id",
            "user",
            "age",
            "family_members",
            "emergency_contact",
            "special_needs",
            "medical_conditions",
            "priority_level",
            "is_high_risk",
            "emergency_supplies_needed",
            "registration_date",
        ]


class CampAdminSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    camp_name = serializers.CharField(source='camp.name', read_only=True)

    class Meta:
        model = CampAdmin
        fields = ["id", "user", "camp", "camp_name", "assigned_at"]


# -----------------------------
# Disaster Serializers
# -----------------------------
class DisasterSerializer(serializers.ModelSerializer):
    class Meta:
        model = Disasters
        fields = [
            "id", "name", "disaster_type", "severity", "status", "location",
            "latitude", "longitude", "description", "start_date", "end_date",
            "estimated_damage", "affected_areas", "affected_population_estimate",
            "impact_radius_km", "impact_area_description", "geojson_boundary",
            "created_at", "updated_at"
        ]
        read_only_fields = ["id", "created_at", "updated_at"]


# -----------------------------
# Camp Serializers
# -----------------------------
class CampSerializer(serializers.ModelSerializer):
    disaster_name = serializers.CharField(source='disasters.name', read_only=True)

    class Meta:
        model = Camp
        fields = [
            "id", "name", "camp_type", "disasters", "disaster_name", "location",
            "latitude", "longitude", "capacity", "population_capacity",
            "contact_person", "contact_phone",
            "email", "status", "coverage_radius_km", "service_area_description",
            "created_at", "updated_at"
        ]
        read_only_fields = ["id", "created_at", "updated_at"]


# -----------------------------
# Alert Serializers
# -----------------------------
class AlertSerializer(serializers.ModelSerializer):
    disaster_name = serializers.CharField(source='Disasters.name', read_only=True)
    status_history = serializers.SerializerMethodField()

    class Meta:
        model = Alert
        fields = [
            "id", "Disasters", "disaster_name", "title", "description",
            "severity", "issued_at", "resolved_at", "status", "status_history"
        ]
        read_only_fields = ["id", "issued_at"]

    def get_status_history(self, obj):
        history = obj.status_history.order_by('-changed_at')
        return AlertStatusHistorySerializer(history, many=True).data


class WeatherAlertSerializer(serializers.ModelSerializer):
    related_disaster_name = serializers.CharField(source='related_disaster.name', read_only=True)
    issued_by_name = serializers.CharField(source='issued_by.username', read_only=True)
    status_history = serializers.SerializerMethodField()

    class Meta:
        model = WeatherAlert
        fields = [
            "id", "weather_type", "risk_level", "status", "location",
            "latitude", "longitude", "title", "description", "forecast_date",
            "expected_severity", "affected_radius_km", "wind_speed_kmh",
            "rainfall_mm", "temperature_celsius", "issued_by", "issued_by_name",
            "issued_at", "updated_at", "expires_at", "related_disaster", "related_disaster_name",
            "status_history"
        ]
        read_only_fields = ["id", "issued_at", "updated_at"]

    def get_status_history(self, obj):
        history = obj.status_history.order_by('-changed_at')
        return WeatherAlertStatusHistorySerializer(history, many=True).data


# -----------------------------
# Resource Serializers
# -----------------------------
class ResourceSerializer(serializers.ModelSerializer):
    class Meta:
        model = Resource
        fields = [
            "id", "name", "category", "description", "unit",
            "total_quantity", "available_quantity",
            "is_active", "created_at"
        ]
        read_only_fields = ["id", "created_at"]


class ResourceInventoryTransactionSerializer(serializers.ModelSerializer):
    resource_name = serializers.CharField(source='resource.name', read_only=True)
    created_by_name = serializers.CharField(source='created_by.username', read_only=True)

    class Meta:
        model = ResourceInventoryTransaction
        fields = [
            "id", "resource", "resource_name", "transaction_type",
            "quantity_delta", "reason", "related_request",
            "related_donation_item", "created_by", "created_by_name", "created_at"
        ]
        read_only_fields = ["id", "created_at"]


class ResourceRequestStatusHistorySerializer(serializers.ModelSerializer):
    changed_by_name = serializers.CharField(source='changed_by.username', read_only=True)

    class Meta:
        model = ResourceRequestStatusHistory
        fields = [
            "id", "previous_status", "new_status",
            "changed_by", "changed_by_name", "note", "changed_at"
        ]
        read_only_fields = ["id", "changed_at"]


class ResourceRequestSerializer(serializers.ModelSerializer):
    resource_name = serializers.CharField(source='resource.name', read_only=True)
    camp_name = serializers.CharField(source='camp.name', read_only=True)
    requested_by_name = serializers.CharField(source='requested_by.username', read_only=True)
    status_history = ResourceRequestStatusHistorySerializer(many=True, read_only=True)

    class Meta:
        model = ResourceRequest
        fields = [
            "id", "camp", "camp_name", "resource", "resource_name",
            "quantity_requested", "quantity_fulfilled", "priority",
            "status", "requested_by", "requested_by_name", "request_date",
            "needed_by", "reason", "status_history"
        ]
        read_only_fields = ["id", "request_date"]


# -----------------------------
# Donation Serializers
# -----------------------------
class DonationItemSerializer(serializers.ModelSerializer):
    resource_name = serializers.CharField(source='resource.name', read_only=True)
    resource_category = serializers.CharField(source='resource.category', read_only=True)

    class Meta:
        model = DonationItem
        fields = ["id", "resource", "resource_name", "resource_category", "quantity"]
        read_only_fields = ["id"]


class DonationSerializer(serializers.ModelSerializer):
    items = DonationItemSerializer(many=True, read_only=True)
    created_by_name = serializers.CharField(source='created_by.username', read_only=True)

    class Meta:
        model = Donation
        fields = [
            "id", "donor_name", "donor_type", "contact_email", "contact_phone",
            "donation_date", "created_by", "created_by_name", "items"
        ]
        read_only_fields = ["id", "donation_date"]


class DonationAcknowledgmentSerializer(serializers.ModelSerializer):
    donation_donor = serializers.CharField(source='donation.donor_name', read_only=True)
    acknowledged_by_name = serializers.CharField(source='acknowledged_by.username', read_only=True)

    class Meta:
        model = DonationAcknowledgment
        fields = [
            "id", "donation", "donation_donor", "acknowledgment_text",
            "acknowledged_by", "acknowledged_by_name", "acknowledged_at"
        ]
        read_only_fields = ["id", "acknowledged_at"]


# -----------------------------
# SOS/Help Request Serializers
# -----------------------------
class HelpRequestSerializer(serializers.ModelSerializer):
    victim_name = serializers.CharField(source='victim.username', read_only=True)
    disaster_name = serializers.CharField(source='disasters.name', read_only=True)
    status_history = serializers.SerializerMethodField()

    class Meta:
        model = HelpRequest
        fields = [
            "id", "victim", "victim_name", "disasters", "disaster_name",
            "description", "location", "requested_at", "status", "status_history"
        ]
        read_only_fields = ["id", "requested_at"]

    def get_status_history(self, obj):
        history = obj.status_history.order_by('-changed_at')
        return HelpRequestStatusHistorySerializer(history, many=True).data


# -----------------------------
# Task Assignment Serializers
# -----------------------------
class TaskAssignmentSerializer(serializers.ModelSerializer):
    volunteer_name = serializers.CharField(source='volunteer.username', read_only=True)
    help_request_description = serializers.CharField(source='help_request.description', read_only=True)
    status_history = serializers.SerializerMethodField()

    class Meta:
        model = TaskAssignment
        fields = [
            "id", "volunteer", "volunteer_name", "task_description",
            "help_request", "help_request_description", "assigned_at", "status", "status_history"
        ]
        read_only_fields = ["id", "assigned_at"]

    def get_status_history(self, obj):
        history = obj.status_history.order_by('-changed_at')
        return TaskAssignmentStatusHistorySerializer(history, many=True).data


# -----------------------------
# Transport Serializers
# -----------------------------
class TransportSerializer(serializers.ModelSerializer):
    camp_name = serializers.CharField(source='assigned_to_camp.name', read_only=True)

    class Meta:
        model = Transport
        fields = [
            "id", "vehicle_number", "transport_type", "capacity",
            "status", "current_location", "assigned_to_camp", "camp_name",
            "last_service_date", "created_at"
        ]
        read_only_fields = ["id", "created_at"]


class TransportTripSerializer(serializers.ModelSerializer):
    transport_vehicle = serializers.CharField(source='transport.vehicle_number', read_only=True)

    class Meta:
        model = TransportTrip
        fields = [
            "id", "transport", "transport_vehicle", "origin", "destination",
            "departure_time", "arrival_time", "status", "cargo_description",
            "assigned_resources", "assigned_volunteers", "notes", "created_at"
        ]
        read_only_fields = ["id", "created_at"]


class AlertStatusHistorySerializer(serializers.ModelSerializer):
    changed_by_name = serializers.CharField(source='changed_by.username', read_only=True)

    class Meta:
        model = AlertStatusHistory
        fields = [
            "id", "previous_status", "new_status",
            "changed_by", "changed_by_name", "note", "changed_at"
        ]
        read_only_fields = ["id", "changed_at"]


class WeatherAlertStatusHistorySerializer(serializers.ModelSerializer):
    changed_by_name = serializers.CharField(source='changed_by.username', read_only=True)

    class Meta:
        model = WeatherAlertStatusHistory
        fields = [
            "id", "previous_status", "new_status",
            "changed_by", "changed_by_name", "note", "changed_at"
        ]
        read_only_fields = ["id", "changed_at"]


class HelpRequestStatusHistorySerializer(serializers.ModelSerializer):
    changed_by_name = serializers.CharField(source='changed_by.username', read_only=True)

    class Meta:
        model = HelpRequestStatusHistory
        fields = [
            "id", "previous_status", "new_status",
            "changed_by", "changed_by_name", "note", "changed_at"
        ]
        read_only_fields = ["id", "changed_at"]


class TaskAssignmentStatusHistorySerializer(serializers.ModelSerializer):
    changed_by_name = serializers.CharField(source='changed_by.username', read_only=True)

    class Meta:
        model = TaskAssignmentStatusHistory
        fields = [
            "id", "previous_status", "new_status",
            "changed_by", "changed_by_name", "note", "changed_at"
        ]
        read_only_fields = ["id", "changed_at"]
