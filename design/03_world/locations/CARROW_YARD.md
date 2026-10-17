# Carrow Yard

**Canonical ID:** `carrow_yard`  
**Formal historical designation:** Carrow District Utility Yard  
**Common designation:** Carrow Yard  
**Site type:** Fortified district utility and maintenance complex  
**Status:** Surviving infrastructure site

## Identity

Carrow Yard was built as a district service complex for infrastructure that could not be allowed to fail quietly.

It housed power conditioning equipment, mechanical plant, repair fabrication, spare components, dispatch personnel, route-service equipment, storage, and local control systems. The high perimeter and controlled gate were practical protections for machinery, fuel, replacement parts, and technicians rather than expressions of military occupation.

The site's severe stone-and-metal architecture is regional civic-industrial construction. It does not imply religious ownership or association with a specific later faction.

## Layout

The surviving complex is organized around a central **Service Court**, used for loading, maintenance staging, equipment movement, and temporary storage.

### Operations House

The large structure at the north end was the administrative and control building. It coordinated service crews, routing, inventories, local utility controls, and emergency response. Its runtime asset retains the legacy ID `command_keep`.

### East Machine House

The eastern utility structure contains heavy electrical and mechanical equipment. Its functions included power conversion, relay switching, machine servicing, and support for local fabrication equipment. Its runtime asset retains the legacy ID `machine_house`.

### West Draft House

The western utility structure contains ventilation, thermal-management, and auxiliary machinery. Its runtime asset retains the legacy ID `utility_fan`.

### South Gate

The primary vehicle and personnel entrance. Its gatehouse controls access to the Service Court and provides protected observation over the approach.

### Alarm Gantry

The structure represented by the legacy `bell_frame` asset is an industrial alarm and signaling frame, not a religious bell installation.

## Historical character

Carrow Yard was neither grand nor unique. Facilities like it existed because regional infrastructure required crews, stockpiles, machinery, secure storage, and local decision-making.

What makes Carrow notable is survival. Its walls, machine buildings, stores, and portions of its control infrastructure remain recognizable enough that the Operator can still infer what the complex was designed to do.

## Present-day ownership

Intentionally unresolved. Do not permanently assign Carrow Yard to a major faction until the faction redesign establishes its current political geography. The site's original identity predates and is independent of its eventual occupants.


## Structure expansion status (design pass, 2026-10-14)

The canonical site roles above remain unchanged. The **proposed**, not-yet-implemented spatial and art design for the West Draft House, Operations House, South Gatehouse and Alarm Gantry is in [Carrow Yard Structures Expansion V1](../../05_levels/CARROW_YARD_STRUCTURES_EXPANSION_V1.md). The first three interiors are now implemented and the West/Operations independent reviews have passed: East Machine House 14×10, West Draft House 12×10, and Operations House 20×14 (32px cells). Those exact dimensions are **shipped runtime facts**, not an approval that the rooms have the desired experiential scale. Gatehouse, Alarm Gantry presentation and the proposed new art families remain unimplemented. Carrow's separate route-authority migration remains pending and owns world entry/exit semantics; room expansion must not recreate a second router.

## Environmental role

Carrow Yard is the first canonical site used to validate exterior-to-interior environment transitions. East Machine House was the initial prototype; West Draft House and Operations House now also have accessible, independently reviewed interiors. These implementation milestones are not themselves in-world canon.

See [Carrow Yard post-interiors planning refresh](../../05_levels/CARROW_YARD_POST_INTERIORS_PLANNING_V1.md) before authoring additional structures or changing production room sizes.
