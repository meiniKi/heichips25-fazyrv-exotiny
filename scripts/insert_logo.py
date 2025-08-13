# SPDX-FileCopyrightText: © 2025 Leo Moser <leo.moser@pm.me>
# Modified by Meinhard Kissich
# SPDX-License-Identifier: Apache-2.0

import pya
import argparse

def insert_logo(input_gds, logo_gds, output_gds, offset=(0, 0)):

    # Read gds
    layout = pya.Layout()
    layout.read(input_gds)
    top = layout.top_cell()

    # Read logo
    layout.read(logo_gds)

    # Insert logo
    fazyrv_small_logo = layout.cell("fazyrv_small_logo")
    top.insert(pya.DCellInstArray(fazyrv_small_logo.cell_index(), pya.DTrans(pya.DTrans.R0, pya.DPoint(offset[0], offset[1]))))

    # Write layout
    layout.write(output_gds)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Insert a logo into the layout.')

    parser.add_argument('input_gds')
    parser.add_argument('logo_gds')
    parser.add_argument('output_gds')
    
    args = parser.parse_args()
    
    insert_logo(args.input_gds, args.logo_gds, args.output_gds, offset=(412.8, 15))
