package com.url.shortener.repository;

import java.time.LocalDate;

public interface DailyClickStatsProjection {

    LocalDate getClickDate();

    Long getCount();
}