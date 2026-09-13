SELECT short_url, COUNT(*)
FROM url_mapping
GROUP BY short_url
HAVING COUNT(*) > 1;

ALTER TABLE url_mapping
ADD CONSTRAINT uk_url_mapping_short_url UNIQUE (short_url);

CREATE INDEX idx_click_event_mapping_date
ON click_event (url_mapping_id, click_date);