allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    project.plugins.whenPluginAdded {
        if (this is com.android.build.gradle.LibraryPlugin) {
            val extension = project.extensions.getByType(com.android.build.gradle.LibraryExtension::class.java)
            if (extension.namespace.isNullOrEmpty()) {
                extension.namespace = project.group.toString()
            }
        }
    }
}

// Disable resource verification for isar_flutter_libs (lStar issue)
subprojects {
    tasks.matching { it.name.contains("verifyReleaseResources") }.configureEach {
        enabled = false
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
