
logo:
	# TopMetal1.drawing 126:0
	python3 make_gds.py --cellname fazyrv_small_logo --scale 0.5 --pixel-size 2.0 --threshold 128 --layer 126 --datatype 0 --invert --merge fazyrv_small_no_font.png gds/fazyrv_small_logo_dwg.gds

	# TopMetal1.nofill 126:23
	python3 make_gds.py --cellname fazyrv_small_logo --scale 0.5 --pixel-size 2.0 --threshold 128 --layer 126 --datatype 23 --invert --merge fazyrv_small_no_fill.png gds/fazyrv_small_logo_no_fill.gds

	python3 combine_gds.py gds/fazyrv_small_logo_dwg.gds gds/fazyrv_small_logo_no_fill.gds gds/fazyrv_small_logo.gds

.PHONY: logo