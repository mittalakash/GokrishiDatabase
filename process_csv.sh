#!/bin/bash
# This script processes a CSV file of Indian postal data and generates SQL INSERT statements.
# v4: Removes internal comments from awk script to prevent shell parsing errors.
# Assumed CSV format in india_pincode.csv: PostOfficeName,Pincode,District,StateName

awk -F, '
BEGIN {
    q = "\x27";
    qq = "\x27\x27";
    state_id = 1; district_id = 1; pincode_id = 1; locality_id = 1;

    print "-- =============================================================================\n-- GOKRISHI E-COMMERCE PLATFORM - SEED DATA (v4.0 - Generated from CSV)\n-- =============================================================================\n-- This script is auto-generated from india_pincode.csv.\n-- It populates the database with comprehensive Indian geodata, using the localities table.\n-- =============================================================================\n\nSET NAMES utf8mb4;";
    print "SET foreign_key_checks = 0;";
    print "TRUNCATE TABLE `localities`;";
    print "TRUNCATE TABLE `pincodes`;";
    print "TRUNCATE TABLE `districts`;";
    print "TRUNCATE TABLE `states`;";
    print "TRUNCATE TABLE `countries`;";
    print "";
    print "INSERT INTO `countries` (`id`, `name`, `iso_code_2`, `phone_code`) VALUES (1, " q "India" q ", " q "IN" q ", " q "+91" q ");";
    print "";
}

{
    if (NR == 1) next;

    officename = $1; pincode = $2; district = $3; state = $4;

    gsub(/^[ \t]+|[ \t]+$/, "", officename); gsub(q, qq, officename);
    gsub(/^[ \t]+|[ \t]+$/, "", pincode);
    gsub(/^[ \t]+|[ \t]+$/, "", district); gsub(q, qq, district);
    gsub(/^[ \t]+|[ \t]+$/, "", state); gsub(q, qq, state);

    if (state == "" || district == "" || pincode == "" || officename == "") next;

    if (!states[state]) {
        states[state] = state_id++;
        state_list[states[state]] = state;
    }

    if (!districts[district"|"state]) {
        districts[district"|"state] = district_id++;
        district_list[district_id] = "(" q district q ", " states[state] ")";
    }

    if (!pincodes[pincode]) {
        pincodes[pincode] = pincode_id++;
        pincode_list[pincode_id] = "(" q pincode q ", " districts[district"|"state] ")";
    }
    
    locality_list[locality_id] = "(" q officename q ", " pincodes[pincode] ")";
    locality_id++;
}

END {
    print "-- Generating States...";
    print "INSERT INTO `states` (`id`, `name`, `country_id`) VALUES";
    for (id=1; id < state_id; id++) {
        printf "(%s, %s%s%s, 1)%s\n", id, q, state_list[id], q, (id == state_id-1 ? ";" : ",");
    }
    print "";

    print "-- Generating Districts...";
    print "INSERT INTO `districts` (`id`, `name`, `state_id`) VALUES";
    for (id=2; id <= district_id; id++) {
        printf "(%s, %s)%s\n", id-1, district_list[id], (id == district_id ? ";" : ",");
    }
    print "";

    print "-- Generating Pincodes...";
    print "INSERT INTO `pincodes` (`id`, `pincode`, `district_id`) VALUES";
    for (id=2; id <= pincode_id; id++) {
        printf "(%s, %s)%s\n", id-1, pincode_list[id], (id == pincode_id ? ";" : ",");
    }
    print "";

    print "-- Generating Localities (Cities, Villages, Areas)...";
    print "INSERT INTO `localities` (`id`, `name`, `pincode_id`) VALUES";
    for (id=1; id < locality_id; id++) {
        printf "(%s, %s)%s\n", id, locality_list[id], (id == locality_id-1 ? ";" : ",");
    }
    print "";
    
    print "SET foreign_key_checks = 1;";
}
' india_pincode.csv > seed_data.sql