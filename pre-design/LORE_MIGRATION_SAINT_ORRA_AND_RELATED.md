The following is an unedited excerpt of the review covering the re-authoring of the forlorn ritualant scene, the ash bell event, saint orra, and various currently locked canonical lore and design. The following is an initial draft and should be reviewed with any subesequent modifications noted and corrected upon migration and implementation of the new canonical lore.

---

Yes. I think you’ve identified the part of the lore that was eating the rest of the game.

The current CORE_LORE.md really does escalate from The Severing → failed arrival → Unnarrival → Non-Recipient → reality/causality/recipient chains becoming unsafe to complete, with provenance failure woven into the structure. That is much more metaphysical than the actual game needs to be. The interesting parts of CUSTODIAN are already more tangible: old institutions, emergency systems, bad commands, abandoned people, ritualized memories, decaying infrastructure, and people still living in the wreckage.

And the good news is: the implemented Orra/Ash-Bell scene can survive this rewrite almost intact.

The live event already has ASK: ORRA?, identifies her internally as the unarrived_saint, contains a Ninth Answer sequence, has begin_orra_late(), a ghost procession, Stilling Pin, white thread, fountain/basin, and even a bellfall_containment knowledge key. The scene is practically begging for a more concrete historical explanation.

The big reauthoring move

I would change the thesis from:

The world broke because certainty/provenance/arrival itself became metaphysically unstable.

to:

The world suffered a real catastrophic collapse. Broken provenance is what happened to history afterward.

That distinction fixes an enormous amount.

Records contradict because governments collapsed. Orders were copied incorrectly. Databases became isolated. Emergency authorities issued conflicting directives. Survivors altered records. Factions preserved politically convenient versions. Some documents are forged. Some are incomplete. Some are perfectly accurate but missing context.

So broken provenance stays because it is a fantastic CUSTODIAN problem.

It just stops being a cosmic substance.

The player can still encounter three records saying three different things and have to decide what to trust. But somewhere underneath them, something actually happened. History is difficult to reconstruct, not literally indeterminate.

That gives you mystery without turning the game into:

“Perhaps the chair was always a horse. Who is to say? 👻”

Which, yeah, I don't think is where this game is strongest.

Saint Orra

I would make one pretty firm canon decision here:

Orra was not a Custodian.

That instantly makes the universe feel larger.

She belonged to a separate old-world civil authority called the Meridian Office.

Not a church. Not another military.

The Meridian Office maintained synchronized civic systems: warning bells, emergency clocks, relay signals, evacuation sequencing, quarantine timing, and regional disaster coordination.

Custodians dealt with physical continuity:

Keep the pumps running.
Seal the gate.
Hold the wall.
Repair the relay.
Maintain the corridor.

The Meridian Office dealt with coordination:

When does the gate close?
Which districts evacuate first?
When does the convoy depart?
Which stations acknowledge the warning?
Has everyone received the order?

Orra's actual historical title could be:

Precentor Orra

“Saint Orra” comes later.

She becomes a saint through folk memory, especially among the people descended from those who survived the catastrophe. Whether the old Meridian Office would have found that title appropriate is irrelevant.

That makes it feel wonderfully historical.

An official Custodian record says:

PRECEPTOR ORRA / MERIDIAN OFFICE / STATION IX

Two centuries later somebody has scratched into a shrine:

SAINT ORRA CAME AT LAST

Same woman.

So what happened?

I would rename the historical event:

The Ash Meridian

That's my strongest recommendation.

It sounds like something that could be simultaneously a historical event, a technical incident, and eventually a quasi-religious observance.

And it gives “meridian” multiple meanings. It happened around a synchronization point, the Meridian Office was involved, and afterward people started using the phrase poetically.

I would keep Ash-Bell, but change what it means.

Ash-Bell is not the apocalypse.

The Ash-Bell Protocol was an emergency warning and containment procedure.

That lets you retain all these existing ash_bell_* runtime paths and concepts instead of ripping plumbing out of Godot. The active lore folder itself is still explicitly built around Ash-Bell, including ASH_BELL_IMPROVEMENTS.md and ASH_BELL_RITUAL_CONTINUING.md.

The Ash-Bell system had nine response stations.

During an extreme containment event, every station had to acknowledge the sequence.

Each acknowledgement was called an Answer.

So:

First Answer.
Second Answer.
...
Eighth Answer.
Ninth Answer.

Orra commanded Station Nine.

And Station Nine did not answer.

That is where your existing Ninth Answer material suddenly becomes meaningful rather than cryptic for cryptic's sake.

Why was Orra late?

This is where I would avoid both “mysterious causality” and “Orra overslept and ended civilization.”

Orra was late because she deliberately left her assigned route.

A lower district's evacuation failed.

Its designated shelter had either partially collapsed or its exit corridor had been sealed prematurely. Hundreds of people were stranded on the wrong side of the containment boundary.

Orra received the order:

Proceed directly to Station Nine.

She knew exactly what that meant.

She also knew that obeying it meant leaving those people behind.

So she diverted.

Not because her orders became metaphysically ambiguous.

Not because some spooky force deleted the destination from her brain.

She made a decision.

That matters enormously because now Orra can be understood in several ways without the underlying facts changing.

To Meridian command, she abandoned her post.

To the people she diverted to save, she was the only official who came back.

To Custodian command, her missing Answer compromised the containment sequence.

To later authorities, she was a convenient person upon whom an institutional catastrophe could be hung.

To survivors, she eventually became Saint Orra.

That's the sort of ambiguity I would keep throughout CUSTODIAN:

not “what happened is unknowable,” but “what did what happened mean?”

Why did being late matter?

This needs one crucial qualification:

Orra did not cause the apocalypse.

Otherwise the entire civilization has the structural resilience of a Christmas-light strand.

The Ash Meridian should reveal a system already in serious trouble.

The containment network was deteriorated. Emergency maintenance had been deferred. One route had already failed. Leadership had waited too long to issue evacuation. Custodian command was forced into a horrible containment decision.

The Ninth Answer was the last redundancy.

Once the Ash-Bell Protocol began, all nine stations were supposed to synchronize the regional closure.

Eight answered.

Nine didn't.

The safe closure interval expired.

For several minutes, the containment geometry remained incomplete.

That interval is the disaster within the disaster.

Ash crossed boundaries it wasn't supposed to cross. Evacuation corridors became unusable. Something industrial, environmental, biological, supernatural, or a combination thereof escaped containment. We can decide the exact physical nature later without making it “uncertainty itself.”

And then Orra finally arrived.

And she still gave the Ninth Answer.

Too late to prevent the breach.

Not too late to stop it spreading farther.

That's why she matters.

That's why she's a saint.

That's why the phrase “Orra comes late” has teeth.

She is simultaneously associated with catastrophe and salvation.

Had Orra arrived on time, perhaps the breach would have been contained.

Had Orra never arrived, an entire region might have died.

And nobody needs to disagree about those facts for people to argue about her for centuries.

That is a much richer historical wound.

The terminology clicks together really nicely

I would canonize the vocabulary roughly like this:

Current / vague term	Reauthored meaning
The Severing	The civilization-scale collapse. Keep it.
Broken provenance	Post-collapse archival/institutional condition, not cosmic law.
Ash-Bell	Emergency warning/containment protocol and its nine-station network.
Ash-Bell Event	Retire as the main historical name.
The Ash Meridian	Historical name for Orra's regional catastrophe.
Ninth Answer	Station Nine's required final response in the Ash-Bell Protocol.
Orra Comes Late	Folk phrase + existing gameplay behavior/motif.
Saint Orra	Posthumous survivor title for Precentor Orra of the Meridian Office.
Unnarrival	I would probably retire this entirely, or demote it to obscure Penitent religious language.
Non-Recipient	Retire from core cosmology.
Bellfall	Retire.
Bellfall Containment	Rename Ninth Answer Containment.
The Open Interval	Name for the dangerous minutes between the missed Ninth Answer and Orra's eventual response.
The Ninth Silence	Excellent later folk/ritual name for that interval.

That last distinction is particularly juicy.

A technical document might say:

OPEN INTERVAL: 11m 42s

A Ritualant says:

“The Ninth Silence lasted eleven minutes.”

A survivor inscription says:

SHE CAME BEFORE THE SILENCE ENDED

Different languages for one known event.

That's exactly the kind of historical texture I'd like CUSTODIAN to have.

And this makes the Forlorn Ritualant scene much better

The current implementation already gives the player an Orra branch, the white thread, Stilling Pin, apparition, ghost procession, and Ninth Answer staging. The Stilling Pin was deliberately redesigned as a grounded ritual tool rather than a giant magical bell McGuffin, too.

Under this version, that room isn't reenacting abstract “failed arrival.”

It's memorializing the Open Interval.

The white thread marks the boundary that should have closed.

The basin is an old civic memorial or ritualized remnant of Station Nine.

The Stilling Pin pins the boundary shut.

The procession represents the evacuees who crossed or died during the Open Interval.

The apparition is Orra.

And Orra Comes Late becomes fantastic.

Imagine a Ritualant combat behavior where the expected response deliberately doesn't occur when the player anticipates it.

You see the telegraph.

Nothing happens.

You reposition.

You commit to something else.

Then Orra arrives.

That isn't random game-design weirdness anymore. It's an enemy culturally reenacting the most famous eleven minutes in its inherited history.

Very CUSTODIAN.

There is one more change I would make

I wouldn't make the Ash Meridian the event that caused The Severing.

The existing core lore currently places Ash-Bell as a catastrophic episode after the Severing, which I think is actually worth retaining.

That keeps your world huge.

The Severing is the macro-collapse.

Maybe its causes are material and comprehensible in principle: war, infrastructure exhaustion, cascading relay failure, political fracture, resource crises, containment disasters, whatever combination we ultimately choose.

The Ash Meridian is one infamous catastrophe that occurred during that collapse.

And it becomes important to the player because it is where the Custodian institution's ideals collided horribly with actual people.

That is much stronger than secretly making this one bell ceremony responsible for everything.

What I'd actually change in the repo first

There is a genuine canon migration here, not just copy editing. CORE_LORE.md currently declares itself the canonical source and explicitly builds toward Unnarrival, the Non-Recipient, Null Warrant Office, dangerous restoration, and anti-arrival cosmology. Meanwhile the runtime already contains names such as ash_bell_unarrived_saint and ash_bell_bellfall_containment.

So I would not do a giant blind rename. First inventory every player-facing and internal dependency:

rg -n -i \
  'broken provenance|unnarrival|unarrived|non-recipient|null warrant|bellfall|ash.?bell|orra|ninth answer|severing' \
  design custodian python-sim/design

Then the first canon patch should center on:

design/03_world/lore/CORE_LORE.md
design/03_world/lore/ASH_BELL_IMPROVEMENTS.md
design/03_world/lore/ASH_BELL_RITUAL_CONTINUING.md


custodian/game/world/events/ash_bell/forlorn_ritualant_site.gd
custodian/game/world/events/ash_bell/ash_bell_event_state.gd
custodian/game/world/events/ash_bell/ash_bell_interactable.gd


custodian/docs/ai_context/CURRENT_STATE.md
custodian/docs/ai_context/CONTEXT.md

The repo guidance explicitly says design/ is the highest Godot-native documentation authority and that runtime/architecture changes should update those design docs first, then the active AI-context material.

So there isn't currently “documentation drift” between the design and old worldview. They currently agree on the worldview you no longer like. Once we make this canon decision, then they'll immediately become stale unless we migrate them together.

My canon vote

Precentor Orra of the Meridian Office was the ninth signal authority of the Ash-Bell emergency network. During the Ash Meridian, she disobeyed a direct order to reach Station Nine because she diverted to a failed civilian evacuation. Her missing Ninth Answer allowed the containment system's Open Interval to begin. She eventually reached the station and gave the Answer too late to prevent the catastrophe, but early enough to arrest its spread. The people she saved and the communities that survived beyond Station Nine later remembered her as Saint Orra.

And the old saying survives:

Orra comes late.

Sometimes it's an accusation.

Sometimes it's a prayer.

Sometimes it means:

Late is not the same as never.

That, I think, gives her an actual human spine. And it lets us start pulling CUSTODIAN away from “reality is paperwork and paperwork broke” while preserving the institutional horror that was actually working.

You've reached the maximum length for this conversation, but you can keep talking by starting a new chat.
