pragma Singleton
import QtQuick

QtObject {
    id: registry

    // ── ASSET TYPE DEFINITIONS ────────────────────────────────────────────────
    readonly property var assetTypes: [
        { name: "Equity",      color: "#00d2ff" },
        { name: "Debt",        color: "#a29bfe" },
        { name: "Real Estate", color: "#ff7675" },
        { name: "Commodity",   color: "#f1c40f" },
        { name: "Crypto",      color: "#6c5ce7" }
    ]

    // ── SUB-TYPE NAMES (per asset type) ──────────────────────────────────────
    function subTypeNames(assetType) {
        if (assetType === "Equity")
            return ["Stock", "Mutual Fund", "ETF", "ESOPs", "Private"]
        if (assetType === "Debt")
            return ["FD/RD", "Bond", "Fund", "Cash & Savings", "Govt. Scheme"]
        if (assetType === "Real Estate")
            return ["Residential", "Commercial", "REITs"]
        if (assetType === "Commodity")
            return ["Physical", "Digital", "ETF/Fund"]
        if (assetType === "Crypto")
            return ["Crypto"]
        return []
    }

    // ── LIQUIDITY ─────────────────────────────────────────────────────────────
    // Returns true if the sub-type is liquid for a given asset type.
    // Illiquid: ESOPs, Private (Equity); Govt. Scheme (Debt);
    //           Residential, Commercial (Real Estate); Physical (Commodity)
    function isLiquid(assetType, subTypeName) {
        if (assetType === "Equity")
            return subTypeName !== "ESOPs" && subTypeName !== "Private"
        if (assetType === "Debt")
            return subTypeName !== "Govt. Scheme"
        if (assetType === "Real Estate")
            return subTypeName === "REITs"
        if (assetType === "Commodity")
            return subTypeName !== "Physical"
        return true  // Crypto — all liquid
    }

    // ── COLOR LOOKUP ──────────────────────────────────────────────────────────
    function colorFor(assetType) {
        if (assetType === "Equity")      return "#00d2ff"
        if (assetType === "Debt")        return "#a29bfe"
        if (assetType === "Real Estate") return "#ff7675"
        if (assetType === "Commodity")   return "#f1c40f"
        if (assetType === "Crypto")      return "#6c5ce7"
        return "#888888"
    }

    // ── FLAT LIQUID / ILLIQUID LISTS ──────────────────────────────────────────
    // Used by PortfolioModel.getLiquidValue / getIlliquidValue
    function allLiquidSubTypes() {
        return ["Stock", "Mutual Fund", "ETF",
                "FD/RD", "Bond", "Fund", "Cash & Savings",
                "REITs",
                "Digital", "ETF/Fund",
                "Crypto"]
    }

    function allIlliquidSubTypes() {
        return ["ESOPs", "Private",
                "Govt. Scheme",
                "Residential", "Commercial",
                "Physical"]
    }
}
