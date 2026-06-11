#!/bin/bash
# Check all entitlements for a conscript after 2 months of service, under martial law
set +e

DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DIR"
MAIN="mil_soc_law/main.catala_en"

# Shared servicemember struct - Conscript, 2 months, ZSU
SM='{"status":"Conscript","formation":"ZSU","service_years":0,"calendar_service_years":0,"monthly_allowance":0,"disability_cause":"No","death_record":"No","serving_abroad":"No","is_basic_service":"Yes","is_academy_student":"No","has_spouse":"No","died_in_service":"No"}'

# Shared family member (placeholder - no family)
FM='{"relationship":0,"is_minor":"No","is_disabled_childhood":"No","is_incapacitated":"No","monthly_income":0,"requests_adaptation":"No"}'

run_scope() {
  local scope=$1
  local input=$2
  echo ""
  echo "═══ $scope ═══"
  local out
  out=$(opam exec -- clerk run -s "$scope" --input="$input" "$MAIN" 2>&1)
  if echo "$out" | grep -q 'RESULT'; then
    echo "$out" | grep -A50 'RESULT' | head -30
  elif echo "$out" | grep -q 'no applicable rule'; then
    echo "  [не визначено — жодне правило не застосовується]"
    echo "$out" | grep 'no applicable rule' -A5 | grep 'output' | sed 's/.*output /  undefined: /' | sed 's/ content.*//'
  else
    echo "$out" | grep -v WARNING | grep -v '^$' | tail -5
  fi
}

echo "╔══════════════════════════════════════════════════════════╗"
echo "║  Сценарій: Новобранець (Conscript), 2 місяці служби,   ║"
echo "║  воєнний стан, ЗСУ, громадянин України                  ║"
echo "╚══════════════════════════════════════════════════════════╝"

# 1. UnderLawProtection (article 3)
run_scope "UnderLawProtection" "{
  \"servicemember\": $SM,
  \"family_member\": $FM,
  \"is_citizen_of_ukraine\": \"Yes\",
  \"cause_of_death_is_excluded\": \"No\",
  \"serving_within_ukraine\": \"Yes\",
  \"participating_in_ukraine_defense\": \"Yes\",
  \"family_member_is_fallen\": \"No\",
  \"member_of_volunteer_territorial_defense\": \"No\",
  \"participating_in_territorial_defense\": \"No\",
  \"disability_origin\": \"ServiceRelated\"
}"

# 2. CivilRights (article 5)
run_scope "CivilRights" "{
  \"sm\": $SM,
  \"is_nationality_Ukraine\": \"Yes\",
  \"serving_within_Ukraine\": \"Yes\",
  \"assigned_non_military_non_disaster_task\": \"No\",
  \"is_protected_person\": \"Yes\",
  \"unlawful_military_authority_decision\": \"No\",
  \"protected_servicemember\": \"Yes\"
}"

# 3. EmploymentGuarantees (article 8)
run_scope "EmploymentGuarantees" "{
  \"sm\": $SM,
  \"family_member\": $FM,
  \"pre_draft_employer_is_filled\": \"No\",
  \"within_one_month_of_discharge\": \"No\",
  \"discharged_without_pension_right\": \"No\",
  \"average_monthly_salary_of_last_employment\": 0,
  \"dismissed_for_health_after_long_service\": \"No\",
  \"conscript_not_employed_before_draft\": \"No\",
  \"discharged_due_to_redundancy\": \"No\",
  \"positive_service_characteristics\": \"No\",
  \"last_year_before_discharge\": \"No\",
  \"completed_special_period_service\": \"No\",
  \"mobilized_or_special_period_draftee\": \"No\"
}"

# 4. MonetaryAllowance (article 9)
run_scope "MonetaryAllowance" "{
  \"sm\": $SM,
  \"has_position\": \"No\",
  \"has_military_rank\": \"No\",
  \"position_base_rate\": 0,
  \"service_rank_factor\": 0,
  \"rank_base_rate\": 0,
  \"seniority_factor\": 0,
  \"length_of_service_premium\": 0,
  \"hazard_duty_surcharge\": 0,
  \"qualification_surcharge\": 0,
  \"academic_surcharge\": 0,
  \"sso_bonus_rate\": 0
}"

# 5. LogisticalProvision (article 9-1)
run_scope "LogisticalProvision" "{
  \"sm\": $SM,
  \"is_draftee_training\": \"Yes\",
  \"transferred_to_new_post\": \"No\",
  \"on_official_travel_ukraine_or_abroad\": \"No\",
  \"state_provision_policy_in_force\": \"No\"
}"

# 6. WartimeBonus (article 9-2) — generic wartime bonus scope
run_scope "WartimeBonus" "{
  \"sm\": $SM,
  \"martial_law_in_force\": \"Yes\",
  \"cmu_determined_amount\": 6000,
  \"destroyed_or_captured_enemy_equipment\": \"No\"
}"

# 6a. KMU168MilitaryRemuneration — specific amounts from KMU Resolution #168
# Conscript not in combat: 6,000 UAH/month for service peculiarities
run_scope "KMU168MilitaryRemuneration" "{
  \"sm\": $SM,
  \"martial_law_in_force\": \"Yes\",
  \"directly_in_combat\": \"No\",
  \"in_combat_area\": \"No\",
  \"on_front_line\": \"No\",
  \"front_line_periods\": 0,
  \"in_command_staff_of_combat_unit\": \"No\",
  \"performing_defense_tasks\": \"No\",
  \"in_training_unit\": \"No\",
  \"instructor_remuneration_category\": 0,
  \"wounded_in_disposal_over_2_months\": \"No\",
  \"is_conscript_service\": \"Yes\",
  \"is_cadet\": \"No\"
}"

# 6b. KMU168DeathBenefit — 15M UAH death benefit during martial law
run_scope "KMU168DeathBenefit" "{
  \"sm\": $SM,
  \"martial_law_in_force\": \"Yes\",
  \"death_during_martial_law\": \"No\"
}"

# 7. LeaveEntitlement (article 10-1)
run_scope "LeaveEntitlement" "{
  \"sm\": $SM,
  \"leave_year\": 2026,
  \"current_year_discharge\": \"No\",
  \"mobilization_declared\": \"Yes\",
  \"martial_law_declared\": \"Yes\",
  \"defense_minister_decision\": \"No\",
  \"dismissal_not_unsuitable_not_convicted\": \"No\",
  \"annual_leave_not_yet_used\": \"No\",
  \"spouse_requests_simultaneous_leave\": \"No\",
  \"special_period_active\": \"Yes\",
  \"martial_law_active\": \"Yes\",
  \"mobilization_service_person\": \"No\",
  \"leaving_service_by_presidential_decision\": \"No\",
  \"annual_leave_unused\": \"No\",
  \"released_from_pow\": \"No\",
  \"servicemember_requests\": \"No\",
  \"conditional_release_status\": \"No\",
  \"on_contract_service\": \"No\",
  \"cmu_determined_max_15_days\": 10
}"

# 8. HealthcareEntitlement (article 11)
run_scope "HealthcareEntitlement" "{
  \"sm\": $SM,
  \"family_member\": $FM,
  \"is_ato_participant\": \"No\",
  \"is_pow_survivor\": \"No\",
  \"is_war_participant\": \"No\",
  \"is_medical_need\": \"No\",
  \"requires_sanatorium\": \"No\",
  \"household_income_per_capita\": 0,
  \"child_sick\": \"No\",
  \"child_hospitalization\": \"No\",
  \"family_member_is_protected\": \"No\",
  \"no_public_hospital_in_residence_area\": \"No\",
  \"actual_service_in_war_zones\": \"No\",
  \"unlawfully_deprived_liberty_and_recently_released\": \"No\",
  \"exceeded_once_per_year\": \"No\",
  \"post_stationary_treatment_per_military_medical_board\": \"No\",
  \"war_time_participant\": \"No\",
  \"child_age\": 0
}"

# 9. HousingEntitlement (article 12)
run_scope "HousingEntitlement" "{
  \"sm\": $SM,
  \"family_member\": $FM,
  \"service_years\": 0,
  \"is_disabled_service\": \"No\",
  \"is_family_of_fallen\": \"No\",
  \"is_internal_displaced\": \"No\",
  \"has_housing_entitlement_used\": \"No\",
  \"has_service_housing\": \"No\",
  \"household_income_per_capita\": 0,
  \"on_housing_waiting_list\": \"No\",
  \"disabled_during_service_or_service_illness\": \"No\",
  \"dismissed_for_age\": \"No\",
  \"dismissed_due_to_redundancy\": \"No\",
  \"fair_market_value_or_state_subsidized_value\": 0,
  \"housing_eligible_person_applies_for_social\": \"No\",
  \"disabled_service_person\": \"No\",
  \"family_of_fallen\": \"No\",
  \"not_yet_received_housing_or_compensation\": \"Yes\",
  \"protected_person\": \"DisabledService\",
  \"cmu_social_benefit_income_limit\": 2684
}"

# 10. BenefitCompensation (article 14)
run_scope "BenefitCompensation" "{
  \"sm\": $SM,
  \"family_member\": $FM,
  \"household_income_per_capita\": 0,
  \"benefit_type\": \"FreeTransport\",
  \"disability_group\": 0,
  \"is_family_of_fallen\": \"No\",
  \"is_pow\": \"No\",
  \"change_of_service_post\": \"No\",
  \"family_reunion_travel\": \"No\",
  \"travel_for_medical_or_official_purpose\": \"No\",
  \"protected_household\": \"No\",
  \"owner_is_war_participant\": \"No\",
  \"war_experience_verified\": \"No\",
  \"treatment_unavailable_domestically\": \"No\"
}"

# 11. PensionAssistance (article 15)
run_scope "PensionAssistance" "{
  \"sm\": $SM,
  \"family_member\": $FM,
  \"service_years\": 0,
  \"monthly_income\": 0,
  \"household_income_per_capita\": 0,
  \"has_disability\": \"No\",
  \"disability_group\": 0,
  \"age\": 20,
  \"is_family_of_fallen\": \"No\",
  \"is_pow\": \"No\",
  \"cause_of_death_is_service\": \"No\",
  \"disability_caused_by_service\": \"No\",
  \"base_service_pension_rate\": 0,
  \"base_disability_pension_rate\": 0,
  \"base_family_pension_rate\": 0,
  \"social_assistance_base_rate\": 0,
  \"social_assistance_income_threshold\": 2684
}"

# 12. OneTimePaymentAmounts (article 16-2)
run_scope "OneTimePaymentAmounts" "{
  \"sm\": $SM,
  \"has_disability\": \"No\",
  \"disability_group\": 0,
  \"death_record\": \"No\",
  \"cause_of_death_is_service\": \"No\",
  \"is_pow\": \"No\",
  \"within_one_year_of_discharge\": \"No\",
  \"eligible_family_count\": 0,
  \"base_one_time_payment_rate\": 0,
  \"disability_group_amount\": 0,
  \"per_family_member_payment_rate\": 0
}"

# ============================================================================
# WoundedWarriorFlow — Parallel Track Tests
# Tests cover legally significant scenarios, not just the happy path.
# PM (subsistence minimum) 2025 = 3028 UAH for OGD calculations.
# ============================================================================

WWF_BASE='"is_combat_injury": true,
  "form_100_has_critical_errors": false,
  "unit_notified_in_writing": false,
  "notification_proof_held": false,
  "certificate_requested": false,
  "certificate_obtained": false,
  "certificate_delayed_or_refused": false,
  "disqualifying_circumstance": false,
  "vlk_conducted": false,
  "vlk_causal_relationship": "NoVlkCausalYet",
  "vlk_fitness": "NoVlkFitnessYet",
  "vlk_severe_wound_confirmed": false,
  "ekopfo_conducted": false,
  "ekopfo_disability_group": "NoDisability",
  "ekopfo_loss_of_capacity_pct": 0,
  "commander_order_100k_issued": false,
  "ogd_claimed": false,
  "subsistence_minimum_uah": 3028'

echo ""
echo "═══ WW Case 1: День 1 — бойове поранення, жодних дій не вжито ═══"
echo "   Очікується: AWOL ризик=true, дія notify_unit=true, дія request_cert=true,"
echo "   дія get_vlk_referral=true, OGD=0"
run_scope "WoundedWarriorFlow" "{
  $WWF_BASE
}"

echo ""
echo "═══ WW Case 2: Повідомлення є, довідки немає, ВЛК іде паралельно ═══"
echo "   Очікується: AWOL ризик=false, request_cert=true, get_vlk_referral=true"
echo "   (Tracks A, B, C всі активні одночасно)"
run_scope "WoundedWarriorFlow" "{
  \"is_combat_injury\": true,
  \"form_100_has_critical_errors\": false,
  \"unit_notified_in_writing\": true,
  \"notification_proof_held\": true,
  \"certificate_requested\": false,
  \"certificate_obtained\": false,
  \"certificate_delayed_or_refused\": false,
  \"disqualifying_circumstance\": false,
  \"vlk_conducted\": false,
  \"vlk_causal_relationship\": \"NoVlkCausalYet\",
  \"vlk_fitness\": \"NoVlkFitnessYet\",
  \"vlk_severe_wound_confirmed\": false,
  \"ekopfo_conducted\": false,
  \"ekopfo_disability_group\": \"NoDisability\",
  \"ekopfo_loss_of_capacity_pct\": 0,
  \"commander_order_100k_issued\": false,
  \"ogd_claimed\": false,
  \"subsistence_minimum_uah\": 3028
}"

echo ""
echo "═══ WW Case 3: Підрозділ затягує довідку — ескалація ═══"
echo "   Очікується: action_escalate_certificate=true, risk_of_causal_link_degradation=false (ВЛК ще не було)"
run_scope "WoundedWarriorFlow" "{
  \"is_combat_injury\": true,
  \"form_100_has_critical_errors\": false,
  \"unit_notified_in_writing\": true,
  \"notification_proof_held\": true,
  \"certificate_requested\": true,
  \"certificate_obtained\": false,
  \"certificate_delayed_or_refused\": true,
  \"disqualifying_circumstance\": false,
  \"vlk_conducted\": false,
  \"vlk_causal_relationship\": \"NoVlkCausalYet\",
  \"vlk_fitness\": \"NoVlkFitnessYet\",
  \"vlk_severe_wound_confirmed\": false,
  \"ekopfo_conducted\": false,
  \"ekopfo_disability_group\": \"NoDisability\",
  \"ekopfo_loss_of_capacity_pct\": 0,
  \"commander_order_100k_issued\": false,
  \"ogd_claimed\": false,
  \"subsistence_minimum_uah\": 3028
}"

echo ""
echo "═══ WW Case 4: ВЛК зробили без довідки → неправильний причинний зв'язок ═══"
echo "   КРИТИЧНИЙ СЦЕНАРІЙ: risk_of_causal_link_degradation=true"
echo "   ВЛК присвоїла PassageOfService замість ProtectionOfMotherland."
echo "   OGD Group I: 120 × PM замість 400 × PM — різниця 847 840 UAH!"
echo "   Очікується: action_consider_vlk_appeal=true, OGD multiplier=120"
run_scope "WoundedWarriorFlow" "{
  \"is_combat_injury\": true,
  \"form_100_has_critical_errors\": false,
  \"unit_notified_in_writing\": true,
  \"notification_proof_held\": true,
  \"certificate_requested\": true,
  \"certificate_obtained\": true,
  \"certificate_delayed_or_refused\": false,
  \"disqualifying_circumstance\": false,
  \"vlk_conducted\": true,
  \"vlk_causal_relationship\": \"PassageOfService\",
  \"vlk_fitness\": \"UnfitExcluded\",
  \"vlk_severe_wound_confirmed\": true,
  \"ekopfo_conducted\": true,
  \"ekopfo_disability_group\": \"Group_I\",
  \"ekopfo_loss_of_capacity_pct\": 80,
  \"commander_order_100k_issued\": false,
  \"ogd_claimed\": false,
  \"subsistence_minimum_uah\": 3028
}"

echo ""
echo "═══ WW Case 5: Повний пакет — ProtectionOfMotherland, Group II ═══"
echo "   Очікується: OGD multiplier=300, OGD amount=908 400 UAH"
echo "   is_eligible_for_100k_remuneration=true, is_eligible_for_disability_war_status=true"
run_scope "WoundedWarriorFlow" "{
  \"is_combat_injury\": true,
  \"form_100_has_critical_errors\": false,
  \"unit_notified_in_writing\": true,
  \"notification_proof_held\": true,
  \"certificate_requested\": true,
  \"certificate_obtained\": true,
  \"certificate_delayed_or_refused\": false,
  \"disqualifying_circumstance\": false,
  \"vlk_conducted\": true,
  \"vlk_causal_relationship\": \"ProtectionOfMotherland\",
  \"vlk_fitness\": \"UnfitExcluded\",
  \"vlk_severe_wound_confirmed\": true,
  \"ekopfo_conducted\": true,
  \"ekopfo_disability_group\": \"Group_II\",
  \"ekopfo_loss_of_capacity_pct\": 60,
  \"commander_order_100k_issued\": false,
  \"ogd_claimed\": false,
  \"subsistence_minimum_uah\": 3028
}"

echo ""
echo "═══ WW Case 6: Дискваліфікаційна обставина (стан сп'яніння) — OGD заблоковано ═══"
echo "   Очікується: is_eligible_for_ogd=false, ogd_multiplier=0, ogd_amount_uah=0"
run_scope "WoundedWarriorFlow" "{
  \"is_combat_injury\": true,
  \"form_100_has_critical_errors\": false,
  \"unit_notified_in_writing\": true,
  \"notification_proof_held\": true,
  \"certificate_requested\": true,
  \"certificate_obtained\": true,
  \"certificate_delayed_or_refused\": false,
  \"disqualifying_circumstance\": true,
  \"vlk_conducted\": true,
  \"vlk_causal_relationship\": \"ProtectionOfMotherland\",
  \"vlk_fitness\": \"FitWithRestrictions\",
  \"vlk_severe_wound_confirmed\": false,
  \"ekopfo_conducted\": true,
  \"ekopfo_disability_group\": \"Group_III\",
  \"ekopfo_loss_of_capacity_pct\": 30,
  \"commander_order_100k_issued\": false,
  \"ogd_claimed\": false,
  \"subsistence_minimum_uah\": 3028
}"

echo ""
echo "═══ WW Case 7: Відсоток втрати без інвалідності (25%) ═══"
echo "   Очікується: ogd_multiplier=1750 (25 × 70), ogd_amount_uah=5 299 000 UAH"
run_scope "WoundedWarriorFlow" "{
  \"is_combat_injury\": true,
  \"form_100_has_critical_errors\": false,
  \"unit_notified_in_writing\": true,
  \"notification_proof_held\": true,
  \"certificate_requested\": true,
  \"certificate_obtained\": true,
  \"certificate_delayed_or_refused\": false,
  \"disqualifying_circumstance\": false,
  \"vlk_conducted\": true,
  \"vlk_causal_relationship\": \"ExecutionOfDuties\",
  \"vlk_fitness\": \"FitWithRestrictions\",
  \"vlk_severe_wound_confirmed\": false,
  \"ekopfo_conducted\": true,
  \"ekopfo_disability_group\": \"NoDisability\",
  \"ekopfo_loss_of_capacity_pct\": 25,
  \"commander_order_100k_issued\": false,
  \"ogd_claimed\": false,
  \"subsistence_minimum_uah\": 3028
}"

echo ""
echo "═══════════════════════════════════════"
echo "  Готово. Всі scope-и перевірені."
echo "═══════════════════════════════════════"

