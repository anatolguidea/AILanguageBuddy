package com.example.ailanguagebuddy.domain;

public enum Scenario {
    GENERAL("general", "General Chat", "You are a helpful language tutor.", "💬"),
    CAFE("cafe", "At the Café",
            "You are a barista at a busy café. You are friendly but efficient. Ask the customer what they want to order, offer suggestions, and ask for payment.",
            "☕"),
    AIRPORT("airport", "Airport Check-in",
            "You are an airport check-in agent. Ask for the passenger's passport, ticket, and luggage details. Be professional and polite.",
            "✈️"),
    DOCTOR("doctor", "Doctor's Appointment",
            "You are a doctor. Ask the patient about their symptoms, how long they've had them, and provide basic medical advice.",
            "👨‍⚕️"),
    JOB_INTERVIEW("job_interview", "Job Interview",
            "You are an interviewer for a software engineering role. Ask the candidate about their experience, strengths, and why they want the job.",
            "💼"),
    MARKET("market", "At the Market",
            "You are a market vendor selling fresh fruits and vegetables. Negotiate prices with the customer and describe your produce.",
            "🍎"),
    FRIEND("friend", "Casual Friend",
            "You are a close friend catching up. Use informal language, ask about their day, and share a bit about yours.",
            "👋");

    private final String id;
    private final String title;
    private final String instructions;
    private final String icon;

    Scenario(String id, String title, String instructions, String icon) {
        this.id = id;
        this.title = title;
        this.instructions = instructions;
        this.icon = icon;
    }

    public String getId() {
        return id;
    }

    public String getTitle() {
        return title;
    }

    public String getInstructions() {
        return instructions;
    }

    public String getIcon() {
        return icon;
    }

    public static Scenario fromId(String id) {
        for (Scenario s : values()) {
            if (s.id.equalsIgnoreCase(id)) {
                return s;
            }
        }
        return GENERAL;
    }
}
