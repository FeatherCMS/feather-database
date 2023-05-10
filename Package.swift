// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "feather-database",
    platforms: [
       .macOS(.v12),
    ],
    products: [
        .library(name: "FeatherDatabase", targets: ["FeatherDatabase"]),
        .library(name: "FeatherPostgresDatabase", targets: ["FeatherPostgresDatabase"]),
        .library(name: "FeatherSQLiteDatabase", targets: ["FeatherSQLiteDatabase"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/postgres-nio", from: "1.14.0"),
        .package(url: "https://github.com/vapor/sqlite-nio", from: "1.5.0"),
    ],
    targets: [
        .target(name: "FeatherDatabase", dependencies: [
        ]),
        .target(name: "FeatherPostgresDatabase", dependencies: [
            .target(name: "FeatherDatabase"),
            .product(name: "PostgresNIO", package: "postgres-nio"),
        ]),
        .target(name: "FeatherSQLiteDatabase", dependencies: [
            .target(name: "FeatherDatabase"),
            .product(name: "SQLiteNIO", package: "sqlite-nio"),
        ]),
        .testTarget(name: "FeatherDatabaseTests", dependencies: [
            .target(name: "FeatherDatabase"),
        ]),
        .testTarget(name: "FeatherPostgresDatabaseTests", dependencies: [
            .target(name: "FeatherPostgresDatabase"),
        ]),
        .testTarget(name: "FeatherSQLiteDatabaseTests", dependencies: [
            .target(name: "FeatherSQLiteDatabase"),
        ]),
    ]
)
