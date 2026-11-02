from game.simulations.world_state.core.hub import (
    CampaignOutcome,
    DerivedInsights,
    ExtractedArtifacts,
    HubState,
    Losses,
    SecondaryVictories,
    apply_campaign_outcome,
    apply_recon,
    generate_campaign_offer,
)


def test_generate_campaign_offer_has_descriptor() -> None:
    hub = HubState(seed=1, capability_flags={"recon_depth": 0, "archive_loss_tolerance": 0})
    scenario = generate_campaign_offer(hub, seed=123)

    assert scenario.difficulty.descriptor in {
        "LOW CONFIDENCE OPERATION",
        "UNSTABLE CONDITIONS",
        "HIGH RISK ENGAGEMENT",
        "SEVERE OPERATIONAL COMPLEXITY",
        "EXTINCTION-LEVEL UNKNOWN",
    }
    assert 0.0 <= scenario.difficulty.score <= 1.0


def test_apply_recon_reduces_unknowns_and_noise() -> None:
    hub = HubState(seed=1, capability_flags={"recon_depth": 2, "subvictory_detection": True})
    scenario = generate_campaign_offer(hub, seed=77)
    previous_unknowns = list(scenario.uncertainty.unknown_fields)
    previous_noise = scenario.uncertainty.noise_level

    refined = apply_recon(hub, scenario)

    assert refined.seed == scenario.seed
    assert refined.difficulty.score == scenario.difficulty.score
    assert len(refined.uncertainty.unknown_fields) <= len(previous_unknowns)
    assert refined.uncertainty.noise_level <= previous_noise
    assert refined.optional_subvictories.discovered is True


def test_apply_campaign_outcome_updates_history() -> None:
    hub = HubState(seed=1, capability_flags={"archive_loss_tolerance": 0})
    scenario = generate_campaign_offer(hub, seed=9)
    outcome = CampaignOutcome(
        scenario_id=scenario.id,
        result="COMPLETE",
        primary_victory_completion=0.9,
        secondary_victories=SecondaryVictories(achieved=["SECONDARY"], failed=[]),
        losses=Losses(archive_loss=0, structural_loss=False),
        extracted_artifacts=ExtractedArtifacts(type_tags=["CULTURAL"], integrity_scores=[0.7]),
        derived_insights=DerivedInsights(
            inferred_tech_lineages=[],
            historical_estimates={},
            region_id="RX-101A",
            difficulty_descriptor="SEVERE OPERATIONAL COMPLEXITY",
        ),
        seed=9,
    )

    apply_campaign_outcome(hub, outcome)

    assert len(hub.campaign_history) == 1
    assert hub.campaign_history[0].scenario_id == outcome.scenario_id
    assert hub.knowledge_archive
