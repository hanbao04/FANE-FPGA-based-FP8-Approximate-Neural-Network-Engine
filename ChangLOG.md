# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0]
### Fixed
- **addmul & mm & conv modules**: Corrected logic handling for edge cases.
    - Updated edge case output to be `0` instead of the previous 2's complement representation.
    - Refactored hardware logic from **LUT2 to LUT3** to accommodate the updated functional requirements.
    - Replace the addition before BRAM as FP adder (Previous it was int adder by mistake)
    - mvm unit change refer to mm/fp8_mm_v100.v
