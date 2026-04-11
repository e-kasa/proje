package com.sedcore.report.model;

import lombok.Builder;
import lombok.Data;
import java.util.List;

/** Sipariş durumu dağılımı — pie/donut chart için */
@Data
@Builder
public class OrderStatusDistribution {
    private List<String>  labels;   // ["Tamamlandı", "Bekliyor", "İptal", "Kargoda"]
    private List<Long>    counts;
    private List<Double>  percents;
}
