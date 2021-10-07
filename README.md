# sujuiko-hfp-manager

## Planning

- [x] Shiny UI base
- [x] Script / function: save latest list of VP blobs to file
  - Slow to fetch the full list every time -> get ready to cache it e.g. every day
- [ ] Create Docker volume logic
  - [ ] Day/hr raw data cache
  - [ ] Obs/jrn volume, shared with sujuikoDB
- [ ] Show VP csv files available
  - [x] File list with sizes
  - [ ] Mark files already in the cache
  - [x] Selectable rows
- [ ] Fetch VP csv files selected from the list (default: all hours) -> background job
- [ ] Restrict VP csv cache to a maximum size, check before fetching
- [ ] Delete VP csv files by selecting from UI
- [ ] Transform selected day VP csv files into <route>_<dir>_<oday>.csv.gz files -> background job
  - If route-dir-oday files already exists, then append
- [ ] Show route-dir-oday files in cache
  - Searchable by route, dir and oday
  - Selectable
- [ ] Deduplicate & normalize selected route-dir-oday files into corresponding jrn and obs files -> background job
- [ ] Show jrn/obs-route-dir-oday files in cache
  - Searchable by route, dir and oday; both jrn and obs must be available
  - Selectable
- [ ] Include database connection parameters & handling
- [ ] List journeys already in database: N by route-dir-oday
- [ ] Copy selected route-dir-oday dumps (jrn & obs) to database -> background job
