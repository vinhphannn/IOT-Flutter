// --- 1. PHẦN MỚI THÊM: ĐỊNH NGHĨA KOTLIN VERSION ---
buildscript {
    // Định nghĩa biến kotlin_version là 1.9.0 (Bản ổn định cho thư viện mới)
    val kotlin_version by extra("2.1.0") 
    
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Classpath cho Android Build Tools (Giữ nguyên hoặc chỉnh tùy version Flutter)
        // Nếu vợ dùng Flutter mới nhất thì thường là 7.3.0 hoặc 8.1.0
        classpath("com.android.tools.build:gradle:7.3.0")
        
        // Classpath cho Kotlin (Quan trọng nhất để sửa lỗi)
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
