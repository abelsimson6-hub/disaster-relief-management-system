"""
Utility functions for location-based matching and operations
"""
from django.db.models import Q
from math import radians, cos, sin, asin, sqrt
from decimal import Decimal


def calculate_distance(lat1, lon1, lat2, lon2):
    """
    Calculate the great circle distance between two points 
    on the earth (specified in decimal degrees)
    Returns distance in kilometers
    """
    if not all([lat1, lon1, lat2, lon2]):
        return None
    
    # Convert decimal degrees to radians
    lat1, lon1, lat2, lon2 = map(radians, [float(lat1), float(lon1), float(lat2), float(lon2)])
    
    # Haversine formula
    dlon = lon2 - lon1
    dlat = lat2 - lat1
    a = sin(dlat/2)**2 + cos(lat1) * cos(lat2) * sin(dlon/2)**2
    c = 2 * asin(sqrt(a))
    r = 6371  # Radius of earth in kilometers
    return c * r


def find_nearby_volunteers(victim_lat, victim_lon, radius_km=50, max_results=10):
    """
    Find available volunteers within a certain radius of the victim
    """
    from users.models import User, Volunteer
    
    if not victim_lat or not victim_lon:
        return Volunteer.objects.none()
    
    # Get all available volunteers with location
    volunteers = Volunteer.objects.filter(
        availability=True,
        user__latitude__isnull=False,
        user__longitude__isnull=False
    ).select_related('user')
    
    nearby_volunteers = []
    for volunteer in volunteers:
        distance = calculate_distance(
            victim_lat, victim_lon,
            float(volunteer.user.latitude), float(volunteer.user.longitude)
        )
        if distance and distance <= radius_km:
            nearby_volunteers.append({
                'volunteer': volunteer,
                'distance_km': round(distance, 2)
            })
    
    # Sort by distance
    nearby_volunteers.sort(key=lambda x: x['distance_km'])
    
    # Return top N volunteers
    return [v['volunteer'] for v in nearby_volunteers[:max_results]]


def find_nearest_camp_admin(user_lat, user_lon, radius_km=100):
    """
    Find the nearest camp admin to a user's location
    """
    from users.models import CampAdmin
    from shelters.models import Camp
    
    if not user_lat or not user_lon:
        return None
    
    # Get all camp admins whose camps have location
    camp_admins = CampAdmin.objects.filter(
        camp__latitude__isnull=False,
        camp__longitude__isnull=False
    ).select_related('camp', 'user')
    
    nearest = None
    min_distance = float('inf')
    
    for camp_admin in camp_admins:
        distance = calculate_distance(
            user_lat, user_lon,
            float(camp_admin.camp.latitude), float(camp_admin.camp.longitude)
        )
        if distance and distance <= radius_km and distance < min_distance:
            min_distance = distance
            nearest = camp_admin
    
    return nearest


def find_nearest_camp(user_lat, user_lon, radius_km=100):
    """
    Find the nearest camp to a user's location
    """
    from shelters.models import Camp
    
    if not user_lat or not user_lon:
        return None
    
    camps = Camp.objects.filter(
        latitude__isnull=False,
        longitude__isnull=False,
        status='active'
    )
    
    nearest = None
    min_distance = float('inf')
    
    for camp in camps:
        distance = calculate_distance(
            user_lat, user_lon,
            float(camp.latitude), float(camp.longitude)
        )
        if distance and distance <= radius_km and distance < min_distance:
            min_distance = distance
            nearest = camp
    
    return nearest

