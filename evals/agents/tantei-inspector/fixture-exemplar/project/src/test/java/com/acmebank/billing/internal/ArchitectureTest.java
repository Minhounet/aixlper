package com.acmebank.billing.internal;

import com.tngtech.archunit.core.domain.JavaClasses;
import com.tngtech.archunit.core.importer.ClassFileImporter;
import com.tngtech.archunit.core.importer.ImportOption;
import org.junit.jupiter.api.Test;

import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.noClasses;

// BILL-4821: written after a JDBC import slipped into the domain in review.
class ArchitectureTest {

    private final JavaClasses classes = new ClassFileImporter()
            .withImportOption(ImportOption.Predefined.DO_NOT_INCLUDE_TESTS)
            .importPackages("com.acmebank.billing.internal");

    @Test
    void domainShouldNotDependOnInfrastructure() {
        noClasses().that().resideInAPackage("..domain..")
                .should().dependOnClassesThat()
                .resideInAnyPackage("..infrastructure..", "java.sql..", "org.springframework..")
                .because("the domain owns its interfaces; adapters implement them")
                .check(classes);
    }

    @Test
    void adaptersShouldOnlyBeReachedThroughDomainInterfaces() {
        noClasses().that().resideInAPackage("..application..")
                .should().dependOnClassesThat().resideInAPackage("..infrastructure..")
                .check(classes);
    }
}
