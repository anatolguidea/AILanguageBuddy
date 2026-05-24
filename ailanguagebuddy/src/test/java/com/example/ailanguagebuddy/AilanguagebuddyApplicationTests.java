package com.example.ailanguagebuddy;

import org.junit.jupiter.api.Disabled;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;

@SpringBootTest
@Disabled("Requires a running PostgreSQL database with Flyway migrations applied. Run manually against a local dev DB.")
class AilanguagebuddyApplicationTests {

    @Test
    void contextLoads() {
    }
}
