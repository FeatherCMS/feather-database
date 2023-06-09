# Feather Database Component

## Getting started

```swift
.package(url: "https://github.com/feathercms/feather-database", from: "1.0.0"),
```

```swift
.product(name: "FeatherDatabase", package: "feather-database"),
```

Database provider services

```swift
.product(name: "FeatherPostgres", package: "feather-database"),
.product(name: "FeatherSQLite", package: "feather-database"),
```    

## Credits

- [SQLKit](https://github.com/vapor/sql-kit)
- [SQLiteKit](https://github.com/vapor/sqlite-kit/tree/main/Sources/SQLiteKit)
- [FluentSQLiteDriver](https://github.com/vapor/fluent-sqlite-driver)
- [FluentPostgresDriver](https://github.com/vapor/fluent-postgres-driver)

Special thanks to [Joannis Orlandos](https://github.com/joannis) for the query string interpolation feedback & implementation sample.
