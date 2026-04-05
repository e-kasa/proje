package com.sedcore.model.reports;

import com.sedcore.enums.StockMovementType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;
import java.util.Map;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class StockMovementSummary {
    private Long totalMovements;
    private Long totalIn;
    private Long totalOut;
    private Map<StockMovementType, Long> countByType;
    private List<DailyMovement> dailyMovements;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class DailyMovement {
        private String date;
        private Long inCount;
        private Long outCount;
        private Long totalCount;
    }
}
