# -*- coding: utf-8 -*-
from odoo import models, api
from odoo.exceptions import UserError
import urllib.parse


class ResPartner(models.Model):
    _inherit = 'res.partner'

    def action_navigate_to_location(self):
        """
        Opens Google Maps with navigation from current location to partner location
        """
        self.ensure_one()
        
        location = self
        
        # Try to build the destination address
        destination_parts = []
        
        # If we have coordinates, use them for more accuracy
        if location.partner_latitude and location.partner_longitude:
            destination = f"{location.partner_latitude},{location.partner_longitude}"
        else:
            # Build address string from available fields
            if location.street:
                destination_parts.append(location.street)
            if location.street2:
                destination_parts.append(location.street2)
            if location.city:
                destination_parts.append(location.city)
            if location.state_id:
                destination_parts.append(location.state_id.name)
            if location.zip:
                destination_parts.append(location.zip)
            if location.country_id:
                destination_parts.append(location.country_id.name)
            
            if not destination_parts:
                raise UserError("This contact doesn't have a valid address or coordinates.")
            
            destination = ", ".join(destination_parts)
        
        # Encode the destination for URL
        destination_encoded = urllib.parse.quote(destination)
        
        # Build Google Maps navigation URL
        # This opens navigation mode from user's current location to the destination
        google_maps_url = f"https://www.google.com/maps/dir/?api=1&destination={destination_encoded}&travelmode=driving"
        
        # Return an action to open the URL
        return {
            'type': 'ir.actions.act_url',
            'url': google_maps_url,
            'target': 'new',
        }
