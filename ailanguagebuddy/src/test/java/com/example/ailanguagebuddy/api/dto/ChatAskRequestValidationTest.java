package com.example.ailanguagebuddy.api.dto;

import jakarta.validation.Validation;
import jakarta.validation.Validator;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import jakarta.validation.ValidatorFactory;

import static org.assertj.core.api.Assertions.assertThat;

@DisplayName("ChatAskRequest validation")
class ChatAskRequestValidationTest {

    private static ValidatorFactory validatorFactory;
    private static Validator validator;

    @BeforeAll
    static void setUpValidator() {
        validatorFactory = Validation.buildDefaultValidatorFactory();
        validator = validatorFactory.getValidator();
    }

    @AfterAll
    static void closeValidator() {
        validatorFactory.close();
    }

    @Test
    @DisplayName("accepts human-readable level labels from existing clients")
    void acceptsHumanReadableLevelLabels() {
        var request = new ChatAskRequest(
                "Hello",
                "English",
                "Romanian",
                "Intermediate",
                "chef_en",
                "en");

        assertThat(validator.validate(request)).isEmpty();
    }

    @Test
    @DisplayName("accepts mode values up to API storage limit")
    void acceptsModeValuesUpToApiStorageLimit() {
        var request = new ChatAskRequest(
                "Hello",
                "English",
                "Romanian",
                "B1",
                "x".repeat(100),
                "en");

        assertThat(validator.validate(request)).isEmpty();
    }

    @Test
    @DisplayName("rejects blank messages")
    void rejectsBlankMessages() {
        var request = new ChatAskRequest(
                "   ",
                "English",
                "Romanian",
                "B1",
                "chef_en",
                "en");

        assertThat(validator.validate(request))
                .anySatisfy(violation -> assertThat(violation.getPropertyPath().toString()).isEqualTo("message"));
    }
}
