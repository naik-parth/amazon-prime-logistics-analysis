import pandas as pd
import numpy as np
from datetime import datetime, timedelta

print("Generating Amazon Prime Fulfillment Data Pipeline...")
np.random.seed(42)

NUM_ORDERS = 5000
START_DATE = datetime(2026, 7, 1)

# Dimension Tables
dim_fc = pd.DataFrame({'fc_id': ['MDW2', 'ORD1', 'IND1', 'CVG3'], 'location': ['Joliet, IL', 'Chicago, IL', 'Indianapolis, IN', 'Cincinnati, OH'], 'automation_level': ['High', 'Medium', 'High', 'Low']})
dim_carrier = pd.DataFrame({'carrier_id': ['AMZL', 'UPS', 'FDX', 'USPS'], 'carrier_name': ['Amazon Logistics', 'UPS', 'FedEx', 'US Postal Service']})

# Fact Orders
order_ids = [f"AMZ-{100000 + i}" for i in range(NUM_ORDERS)]
is_prime = np.random.choice([True, False], size=NUM_ORDERS, p=[0.8, 0.2])
fact_orders = pd.DataFrame({'order_id': order_ids, 'customer_id': [np.random.randint(5000, 9999) for _ in range(NUM_ORDERS)], 'is_prime': is_prime, 'order_value_usd': np.round(np.random.uniform(15.0, 250.0), 2)})

# Fact Tracking Logs
tracking_records = []
for idx, order in fact_orders.iterrows():
    order_id = order['order_id']
    fc = np.random.choice(dim_fc['fc_id'], p=[0.4, 0.3, 0.2, 0.1])
    carrier = np.random.choice(dim_carrier['carrier_id'], p=[0.6, 0.2, 0.15, 0.05])
    
    order_time = START_DATE + timedelta(days=np.random.randint(0, 90), hours=np.random.randint(0, 23))
    tracking_records.append({'order_id': order_id, 'fc_id': fc, 'carrier_id': carrier, 'event_status': 'Order Placed', 'event_timestamp': order_time})
    
    # Bottleneck Injection
    pick_time = order_time + timedelta(hours=np.random.uniform(1, 4))
    tracking_records.append({'order_id': order_id, 'fc_id': fc, 'carrier_id': carrier, 'event_status': 'Inventory Picked', 'event_timestamp': pick_time})
    
    pack_hours = np.random.uniform(12, 36) if fc == 'MDW2' else np.random.uniform(1, 6)
    pack_time = pick_time + timedelta(hours=pack_hours)
    tracking_records.append({'order_id': order_id, 'fc_id': fc, 'carrier_id': carrier, 'event_status': 'Order Packed', 'event_timestamp': pack_time})
    
    ship_time = pack_time + timedelta(hours=np.random.uniform(1, 8))
    tracking_records.append({'order_id': order_id, 'fc_id': fc, 'carrier_id': carrier, 'event_status': 'Handed to Carrier', 'event_timestamp': ship_time})
    
    transit_hours = np.random.uniform(36, 72) if carrier == 'USPS' else np.random.uniform(12, 36)
    deliver_time = ship_time + timedelta(hours=transit_hours)
    
    if np.random.rand() > 0.02:
        tracking_records.append({'order_id': order_id, 'fc_id': fc, 'carrier_id': carrier, 'event_status': 'Delivered', 'event_timestamp': deliver_time})
    else:
        tracking_records.append({'order_id': order_id, 'fc_id': fc, 'carrier_id': carrier, 'event_status': 'Lost in Transit', 'event_timestamp': ship_time + timedelta(hours=48)})

fact_tracking_logs = pd.DataFrame(tracking_records)
fact_tracking_logs['event_timestamp'] = fact_tracking_logs['event_timestamp'].dt.strftime('%Y-%m-%d %H:%M:%S')

dim_fc.to_csv('dim_fc.csv', index=False)
dim_carrier.to_csv('dim_carrier.csv', index=False)
fact_orders.to_csv('fact_orders.csv', index=False)
fact_tracking_logs.to_csv('fact_tracking_logs.csv', index=False)
print("Pipeline Complete.")