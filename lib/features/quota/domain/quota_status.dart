/// Represents the health and availability status of quota data.
enum QuotaDataStatus {
  /// Fresh, recently updated quota data.
  fresh,

  /// Data exists but hasn't been updated within the stale threshold.
  stale,

  /// No quota data file has been created or found yet.
  missing,

  /// An error occurred while reading or parsing the quota data.
  error,
}
