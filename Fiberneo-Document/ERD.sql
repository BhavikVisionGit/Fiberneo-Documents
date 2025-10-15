-- Fiberneo Database ERD (Entity Relationship Diagram)
-- Generated from FiberneoDB.sql
-- This file contains a Mermaid ER diagram representation of the database schema

```mermaid
erDiagram
    %% Core Geographic Tables
    PRIMARY_GEO_L1 {
        int ID PK
        varchar NAME
        varchar CODE
    }
    
    PRIMARY_GEO_L2 {
        int ID PK
        varchar NAME
        varchar CODE
        int PRIMARY_GEO_L1_ID_FK FK
    }
    
    PRIMARY_GEO_L3 {
        int ID PK
        varchar NAME
        varchar CODE
        int PRIMARY_GEO_L2_ID_FK FK
    }
    
    PRIMARY_GEO_L4 {
        int ID PK
        varchar NAME
        varchar CODE
        int PRIMARY_GEO_L3_ID_FK FK
    }

    %% Core Network Infrastructure
    AREA {
        int ID PK
        varchar CODE
        varchar NAME
        int SIZE
        varchar BOUNDARY_JSON
        decimal LATITUDE
        decimal LONGITUDE
        int PRIMARY_GEO_L1_FK FK
        int PRIMARY_GEO_L2_FK FK
        int PRIMARY_GEO_L3_FK FK
        int PRIMARY_GEO_L4_FK FK
        int AOI_ID FK
        int CIRCUIT_ID FK
        int CREATOR FK
        int LAST_MODIFIER FK
    }

    LINK {
        int ID PK
        varchar CODE
        varchar NAME
        int DISTANCE_COVERED
        varchar BOUNDARY_JSON
        decimal START_LAT
        decimal START_LONG
        decimal END_LAT
        decimal END_LONG
        int PRIMARY_GEO_L1_FK FK
        int PRIMARY_GEO_L2_FK FK
        int PRIMARY_GEO_L3_FK FK
        int PRIMARY_GEO_L4_FK FK
        int AOI_ID FK
        int CIRCUIT_ID FK
        int CREATOR FK
        int LAST_MODIFIER FK
    }

    FACILITY {
        int id PK
        varchar NAME
        varchar CODE
        varchar ADDRESS
        decimal LATITUDE
        decimal LONGITUDE
        enum TYPE
        int PRIMARY_GEO_L1_FK FK
        int PRIMARY_GEO_L2_FK FK
        int PRIMARY_GEO_L3_FK FK
        int PRIMARY_GEO_L4_FK FK
        int LINK_ID FK
        int CIRCUIT_ID FK
        int CREATOR FK
        int LAST_MODIFIER FK
    }

    %% Physical Infrastructure
    STRUCTURE {
        int ID PK
        varchar NAME
        varchar CODE
        decimal LATITUDE
        decimal LONGITUDE
        int AREA_ID FK
        int CONDUIT_ID FK
        int PRIMARY_GEO_L1_FK FK
        int PRIMARY_GEO_L2_FK FK
        int PRIMARY_GEO_L3_FK FK
        int PRIMARY_GEO_L4_FK FK
        int VENDOR FK
        int CREATOR FK
        int LAST_MODIFIER FK
    }

    CONDUIT {
        int ID PK
        varchar CODE
        varchar NAME
        decimal START_LAT
        decimal START_LONG
        decimal END_LAT
        decimal END_LONG
        int AREA_ID FK
        int LINK_ID FK
        int SPAN_ID FK
        int VENDOR FK
        int CREATOR FK
        int LAST_MODIFIER FK
    }

    SPAN {
        int ID PK
        varchar CODE
        varchar NAME
        int AREA_ID FK
        int PRIMARY_GEO_L1_FK FK
        int PRIMARY_GEO_L2_FK FK
        int PRIMARY_GEO_L3_FK FK
        int PRIMARY_GEO_L4_FK FK
        int VENDOR FK
        int CREATOR FK
        int LAST_MODIFIER FK
    }

    TRANSMEDIA {
        int ID PK
        varchar CODE
        varchar NAME
        int AREA_ID FK
        int LINK_ID FK
        int CONDUIT_ID FK
        int SEGMENT_ID FK
        int PRIMARY_GEO_L1_FK FK
        int PRIMARY_GEO_L2_FK FK
        int PRIMARY_GEO_L3_FK FK
        int PRIMARY_GEO_L4_FK FK
        int VENDOR FK
        int CREATOR FK
        int LAST_MODIFIER FK
    }

    %% Equipment and Devices
    EQUIPMENT {
        int ID PK
        varchar CODE
        varchar NAME
        enum TYPE
        decimal LATITUDE
        decimal LONGITUDE
        int FACILITY_ID FK
        int AREA_ID FK
        int LINK_ID FK
        int SHELF_ID FK
        int PRIMARY_GEO_L1_FK FK
        int PRIMARY_GEO_L2_FK FK
        int PRIMARY_GEO_L3_FK FK
        int PRIMARY_GEO_L4_FK FK
        int VENDOR FK
        int CREATOR FK
        int LAST_MODIFIER FK
    }

    PORT {
        int ID PK
        varchar NAME
        int FACILITY_ID FK
        int EQUIPMENT_ID FK
        int STRAND_ID FK
        int TRANSMEDIA_ID FK
    }

    STRAND {
        int ID PK
        varchar NAME
        int EQUIPMENT_ID FK
        int TRANSMEDIA_ID FK
        int CREATOR FK
        int LAST_MODIFIER FK
    }

    %% Physical Infrastructure Hierarchy
    FLOOR {
        int ID PK
        varchar NAME
        int FACILITY_ID FK
        int CREATOR FK
        int LAST_MODIFIER FK
    }

    ROOM {
        int ID PK
        varchar NAME
        int FLOOR_ID FK
        int PARENT_ROOM_ID FK
        int CREATOR FK
        int LAST_MODIFIER FK
    }

    RACK {
        int ID PK
        varchar NAME
        int FACILITY_ID FK
        int ROOM_ID FK
        int CREATOR FK
        int LAST_MODIFIER FK
    }

    SHELF {
        int ID PK
        varchar NAME
        int RACK_ID FK
        int CREATOR FK
        int LAST_MODIFIER FK
    }

    %% Reference Points and Obstacles
    REFERENCE_POINT {
        int ID PK
        varchar NAME
        decimal LATITUDE
        decimal LONGITUDE
        int STRUCTURE_ID FK
        int PRIMARY_GEO_L1_FK FK
        int PRIMARY_GEO_L2_FK FK
        int PRIMARY_GEO_L3_FK FK
        int PRIMARY_GEO_L4_FK FK
        int CREATOR FK
        int LAST_MODIFIER FK
    }

    OBSTACLE {
        int ID PK
        varchar NAME
        decimal LATITUDE
        decimal LONGITUDE
        int AREA_ID FK
        int PRIMARY_GEO_L1_FK FK
        int PRIMARY_GEO_L2_FK FK
        int PRIMARY_GEO_L3_FK FK
        int PRIMARY_GEO_L4_FK FK
        int CREATOR FK
        int LAST_MODIFIER FK
    }

    %% Customer Management
    CUSTOMER_INFO {
        int ID PK
        varchar NAME
        varchar EMAIL
        varchar PHONE
        int CREATOR FK
        int LAST_MODIFIER FK
    }

    CUSTOMER_ORDER {
        int ID PK
        varchar ORDER_NUMBER
        int CUSTOMER_ID FK
        int CREATOR FK
        int LAST_MODIFIER FK
    }

    CUSTOMER_SITE {
        int ID PK
        varchar NAME
        varchar ADDRESS
        decimal LATITUDE
        decimal LONGITUDE
        int CUSTOMER_ORDER_ID FK
        int FACILITY_ID FK
        int PRIMARY_GEO_L1_FK FK
        int PRIMARY_GEO_L2_FK FK
        int PRIMARY_GEO_L3_FK FK
        int PRIMARY_GEO_L4_FK FK
        int CREATOR FK
        int LAST_MODIFIER FK
    }

    %% Circuit Management
    CIRCUIT {
        int ID PK
        varchar NAME
        varchar CODE
        int SPAN_ID FK
        int CREATOR FK
        int LAST_MODIFIER FK
    }

    SEGMENT {
        int ID PK
        varchar NAME
        int LINK_ID FK
    }

    %% Actual Implementation Tables (Physical Deployments)
    ACTUAL_FACILITY {
        int ID PK
        varchar CODE
        varchar NAME
        decimal LATITUDE
        decimal LONGITUDE
        int FACILITY_ID FK
        int AREA_ID FK
        int LINK_ID FK
        int PRIMARY_GEO_L1_FK FK
        int PRIMARY_GEO_L2_FK FK
        int PRIMARY_GEO_L3_FK FK
        int PRIMARY_GEO_L4_FK FK
        int CREATOR FK
        int LAST_MODIFIER FK
    }

    ACTUAL_CONDUIT {
        int ID PK
        varchar CODE
        varchar NAME
        decimal START_LAT
        decimal START_LONG
        decimal END_LAT
        decimal END_LONG
        int CONDUIT_ID FK
        int AREA_ID FK
        int LINK_ID FK
        int ACTUAL_SPAN_ID FK
        int VENDOR FK
        int CREATOR FK
        int LAST_MODIFIER FK
    }

    ACTUAL_EQUIPMENT {
        int ID PK
        varchar CODE
        varchar NAME
        enum TYPE
        decimal LATITUDE
        decimal LONGITUDE
        int EQUIPMENT_ID FK
        int FACILITY_ID FK
        int AREA_ID FK
        int LINK_ID FK
        int SHELF_ID FK
        int PRIMARY_GEO_L1_FK FK
        int PRIMARY_GEO_L2_FK FK
        int PRIMARY_GEO_L3_FK FK
        int PRIMARY_GEO_L4_FK FK
        int VENDOR FK
        int CREATOR FK
        int LAST_MODIFIER FK
    }

    ACTUAL_STRUCTURE {
        int ID PK
        varchar CODE
        varchar NAME
        decimal LATITUDE
        decimal LONGITUDE
        int STRUCTURE_ID FK
        int AREA_ID FK
        int LINK_ID FK
        int CIRCUIT_ID FK
        int PRIMARY_GEO_L1_FK FK
        int PRIMARY_GEO_L2_FK FK
        int PRIMARY_GEO_L3_FK FK
        int PRIMARY_GEO_L4_FK FK
        int CREATOR FK
        int LAST_MODIFIER FK
    }

    ACTUAL_SPAN {
        int ID PK
        varchar CODE
        varchar NAME
        int SPAN_ID FK
        int LINK_ID FK
        int PRIMARY_GEO_L1_FK FK
        int PRIMARY_GEO_L2_FK FK
        int PRIMARY_GEO_L3_FK FK
        int PRIMARY_GEO_L4_FK FK
        int VENDOR FK
        int CREATOR FK
        int LAST_MODIFIER FK
    }

    ACTUAL_TRANSMEDIA {
        int ID PK
        varchar CODE
        varchar NAME
        int TRANSMEDIA_ID FK
        int AREA_ID FK
        int LINK_ID FK
        int ACTUAL_CONDUIT_ID FK
        int PRIMARY_GEO_L1_FK FK
        int PRIMARY_GEO_L2_FK FK
        int PRIMARY_GEO_L3_FK FK
        int PRIMARY_GEO_L4_FK FK
        int VENDOR FK
        int CREATOR FK
        int LAST_MODIFIER FK
    }

    %% Deviation Tables (Change Management)
    FACILITY_DEVIATION {
        int id PK
        varchar NAME
        int FACILITY_ID FK
        int LINK_ID FK
        int PRIMARY_GEO_L1_FK FK
        int PRIMARY_GEO_L2_FK FK
        int PRIMARY_GEO_L3_FK FK
        int PRIMARY_GEO_L4_FK FK
        int CREATOR FK
        int LAST_MODIFIER FK
    }

    CONDUIT_DEVIATION {
        int ID PK
        varchar NAME
        int CONDUIT_ID FK
        int SPAN_DEVIATION_ID FK
        int VENDOR FK
        int CREATOR FK
        int LAST_MODIFIER FK
    }

    EQUIPMENT_DEVIATION {
        int ID PK
        varchar NAME
        int EQUIPMENT_ID FK
        int AREA_ID FK
        int LINK_ID FK
        int PRIMARY_GEO_L1_FK FK
        int PRIMARY_GEO_L2_FK FK
        int PRIMARY_GEO_L3_FK FK
        int PRIMARY_GEO_L4_FK FK
        int CREATOR FK
        int LAST_MODIFIER FK
    }

    STRUCTURE_DEVIATION {
        int ID PK
        varchar NAME
        int STRUCTURE_ID FK
        int AREA_ID FK
        int PRIMARY_GEO_L1_FK FK
        int PRIMARY_GEO_L2_FK FK
        int PRIMARY_GEO_L3_FK FK
        int PRIMARY_GEO_L4_FK FK
        int CREATOR FK
        int LAST_MODIFIER FK
    }

    SPAN_DEVIATION {
        int ID PK
        varchar NAME
        int SPAN_ID FK
        int AREA_ID FK
        int PRIMARY_GEO_L1_FK FK
        int PRIMARY_GEO_L2_FK FK
        int PRIMARY_GEO_L3_FK FK
        int PRIMARY_GEO_L4_FK FK
        int CREATOR FK
        int LAST_MODIFIER FK
    }

    TRANSMEDIA_DEVIATION {
        int ID PK
        varchar NAME
        int TRANSMEDIA_ID FK
        int AREA_ID FK
        int LINK_ID FK
        int CONDUIT_DEVIATION_ID FK
        int PRIMARY_GEO_L1_FK FK
        int PRIMARY_GEO_L2_FK FK
        int PRIMARY_GEO_L3_FK FK
        int PRIMARY_GEO_L4_FK FK
        int CREATOR FK
        int LAST_MODIFIER FK
    }

    OBSTACLE_DEVIATION {
        int ID PK
        varchar NAME
        int OBSTACLE_ID FK
        int AREA_ID FK
        int PRIMARY_GEO_L1_FK FK
        int PRIMARY_GEO_L2_FK FK
        int PRIMARY_GEO_L3_FK FK
        int PRIMARY_GEO_L4_FK FK
        int CREATOR FK
        int LAST_MODIFIER FK
    }

    REFERENCE_POINT_DEVIATION {
        int ID PK
        varchar NAME
        int REFERENCE_POINT_ID FK
        int STRUCTURE_DEVIATION_ID FK
        int PRIMARY_GEO_L1_FK FK
        int PRIMARY_GEO_L2_FK FK
        int PRIMARY_GEO_L3_FK FK
        int PRIMARY_GEO_L4_FK FK
        int CREATOR FK
        int LAST_MODIFIER FK
    }

    %% Supporting Tables
    USER {
        int ID PK
        varchar NAME
        varchar EMAIL
        varchar USERNAME
    }

    VENDOR {
        int ID PK
        varchar NAME
        varchar CODE
        varchar CONTACT_INFO
        int CREATOR FK
        int LAST_MODIFIER FK
    }

    AREA_OF_INTEREST {
        int ID PK
        varchar TERRAIN_TYPE
        decimal ELEVATION_FROM_SEA_LEVEL
        varchar GEOGRAPHICAL_FEATURES
        varchar LAND_USE_TYPE
        int AREA_ID FK
        int CREATOR FK
        int LAST_MODIFIER FK
    }

    ATTRIBUTE {
        int ID PK
        varchar NAME
        varchar TYPE
        varchar VALUE
    }

    NETWORK_EQUIPMENT {
        int ID PK
        varchar NAME
        varchar TYPE
        int EQUIPMENT_ID FK
        int ATTRIBUTE_ID FK
    }

    ALARM_LIBRARY {
        int ID PK
        varchar NAME
        varchar DESCRIPTION
        varchar SEVERITY
    }

    ALARM_DETAILS {
        int ID PK
        varchar ALARM_ID
        varchar DESCRIPTION
        int ALARM_LIBRARY_ID FK
        int CREATOR FK
        int LAST_MODIFIER FK
    }

    RULE_TEMPLATE {
        int id PK
        varchar NAME
        text RULE_DEFINITION
        int CREATOR FK
        int LAST_MODIFIER FK
    }

    %% Relationships
    PRIMARY_GEO_L1 ||--o{ PRIMARY_GEO_L2 : "contains"
    PRIMARY_GEO_L2 ||--o{ PRIMARY_GEO_L3 : "contains"
    PRIMARY_GEO_L3 ||--o{ PRIMARY_GEO_L4 : "contains"

    AREA ||--o{ LINK : "contains"
    AREA ||--o{ FACILITY : "contains"
    AREA ||--o{ STRUCTURE : "contains"
    AREA ||--o{ CONDUIT : "contains"
    AREA ||--o{ SPAN : "contains"
    AREA ||--o{ TRANSMEDIA : "contains"
    AREA ||--o{ EQUIPMENT : "contains"
    AREA ||--o{ OBSTACLE : "contains"

    LINK ||--o{ FACILITY : "connects"
    LINK ||--o{ CONDUIT : "contains"
    LINK ||--o{ TRANSMEDIA : "contains"
    LINK ||--o{ EQUIPMENT : "contains"

    FACILITY ||--o{ FLOOR : "contains"
    FACILITY ||--o{ EQUIPMENT : "houses"
    FACILITY ||--o{ PORT : "provides"
    FACILITY ||--o{ RACK : "contains"

    FLOOR ||--o{ ROOM : "contains"
    ROOM ||--o{ RACK : "contains"
    RACK ||--o{ SHELF : "contains"
    SHELF ||--o{ EQUIPMENT : "holds"

    STRUCTURE ||--o{ REFERENCE_POINT : "has"
    STRUCTURE ||--o{ CONDUIT : "supports"

    CONDUIT ||--o{ TRANSMEDIA : "contains"
    SPAN ||--o{ CONDUIT : "contains"
    SEGMENT ||--o{ TRANSMEDIA : "contains"

    EQUIPMENT ||--o{ PORT : "provides"
    EQUIPMENT ||--o{ STRAND : "contains"
    TRANSMEDIA ||--o{ STRAND : "contains"

    CUSTOMER_INFO ||--o{ CUSTOMER_ORDER : "places"
    CUSTOMER_ORDER ||--o{ CUSTOMER_SITE : "defines"
    CUSTOMER_SITE ||--o{ FACILITY : "located_at"

    CIRCUIT ||--o{ SPAN : "uses"
    CIRCUIT ||--o{ AREA : "serves"
    CIRCUIT ||--o{ LINK : "traverses"
    CIRCUIT ||--o{ FACILITY : "connects"

    %% Actual Implementation Relationships
    FACILITY ||--o{ ACTUAL_FACILITY : "implemented_as"
    CONDUIT ||--o{ ACTUAL_CONDUIT : "implemented_as"
    EQUIPMENT ||--o{ ACTUAL_EQUIPMENT : "implemented_as"
    STRUCTURE ||--o{ ACTUAL_STRUCTURE : "implemented_as"
    SPAN ||--o{ ACTUAL_SPAN : "implemented_as"
    TRANSMEDIA ||--o{ ACTUAL_TRANSMEDIA : "implemented_as"

    %% Deviation Relationships
    FACILITY ||--o{ FACILITY_DEVIATION : "has_deviations"
    CONDUIT ||--o{ CONDUIT_DEVIATION : "has_deviations"
    EQUIPMENT ||--o{ EQUIPMENT_DEVIATION : "has_deviations"
    STRUCTURE ||--o{ STRUCTURE_DEVIATION : "has_deviations"
    SPAN ||--o{ SPAN_DEVIATION : "has_deviations"
    TRANSMEDIA ||--o{ TRANSMEDIA_DEVIATION : "has_deviations"
    OBSTACLE ||--o{ OBSTACLE_DEVIATION : "has_deviations"
    REFERENCE_POINT ||--o{ REFERENCE_POINT_DEVIATION : "has_deviations"

    %% User and Vendor Relationships
    USER ||--o{ AREA : "creates"
    USER ||--o{ LINK : "creates"
    USER ||--o{ FACILITY : "creates"
    USER ||--o{ STRUCTURE : "creates"
    USER ||--o{ CONDUIT : "creates"
    USER ||--o{ EQUIPMENT : "creates"
    USER ||--o{ TRANSMEDIA : "creates"

    VENDOR ||--o{ FACILITY : "supplies"
    VENDOR ||--o{ STRUCTURE : "supplies"
    VENDOR ||--o{ CONDUIT : "supplies"
    VENDOR ||--o{ EQUIPMENT : "supplies"
    VENDOR ||--o{ TRANSMEDIA : "supplies"
    VENDOR ||--o{ SPAN : "supplies"

    %% Geographic Relationships
    PRIMARY_GEO_L1 ||--o{ AREA : "located_in"
    PRIMARY_GEO_L2 ||--o{ AREA : "located_in"
    PRIMARY_GEO_L3 ||--o{ AREA : "located_in"
    PRIMARY_GEO_L4 ||--o{ AREA : "located_in"

    PRIMARY_GEO_L1 ||--o{ LINK : "traverses"
    PRIMARY_GEO_L2 ||--o{ LINK : "traverses"
    PRIMARY_GEO_L3 ||--o{ LINK : "traverses"
    PRIMARY_GEO_L4 ||--o{ LINK : "traverses"

    PRIMARY_GEO_L1 ||--o{ FACILITY : "located_in"
    PRIMARY_GEO_L2 ||--o{ FACILITY : "located_in"
    PRIMARY_GEO_L3 ||--o{ FACILITY : "located_in"
    PRIMARY_GEO_L4 ||--o{ FACILITY : "located_in"

    %% Area of Interest
    AREA_OF_INTEREST ||--o{ AREA : "describes"
    AREA_OF_INTEREST ||--o{ LINK : "describes"

    %% Equipment and Network
    EQUIPMENT ||--o{ NETWORK_EQUIPMENT : "configured_as"
    ATTRIBUTE ||--o{ NETWORK_EQUIPMENT : "defines"

    %% Alarm Management
    ALARM_LIBRARY ||--o{ ALARM_DETAILS : "defines"

    %% Rule Management
    RULE_TEMPLATE ||--o{ TRANSMEDIA : "applies_to"
    RULE_TEMPLATE ||--o{ ACTUAL_TRANSMEDIA : "applies_to"
```

-- Key Relationships Summary:
-- 1. Geographic Hierarchy: PRIMARY_GEO_L1 -> PRIMARY_GEO_L2 -> PRIMARY_GEO_L3 -> PRIMARY_GEO_L4
-- 2. Network Infrastructure: AREA contains LINK, FACILITY, STRUCTURE, CONDUIT, SPAN, TRANSMEDIA, EQUIPMENT
-- 3. Physical Hierarchy: FACILITY -> FLOOR -> ROOM -> RACK -> SHELF -> EQUIPMENT
-- 4. Implementation: Each planned entity has an ACTUAL_* counterpart for physical deployment
-- 5. Change Management: Each entity has a *_DEVIATION table for tracking changes
-- 6. Customer Management: CUSTOMER_INFO -> CUSTOMER_ORDER -> CUSTOMER_SITE -> FACILITY
-- 7. Circuit Management: CIRCUIT connects multiple network elements
-- 8. User Management: USER creates and modifies all entities
-- 9. Vendor Management: VENDOR supplies various network components
