# Adapted from the xolotl project for use in tinnitus project.
# Generates documentation based on the comments within each file. 
# Intended to be used in conjunction with build_docs.py

import os
from glob import glob

def comment2docs(filename, file, out_file, first, root_pth, a = -1):

    lines = tuple(open(file, 'r'))

    z = -1
    lastcomment = -1
    z_range_min = 0
    is_class = False
    prev_comment = True
    fn_names = []

    # Classes need to be handled differently because method functions may be in the file.
    if 'stimulusgeneration' in filename.lower():

        # Get line number and name of all functions within class
        fns = [(ind, line.strip()) for ind, line in enumerate(lines) if line.strip().find('function') == 0]

        # Find exact function name
        for i in range(0, len(fns)):
            curr_fn = fns[i][1].replace(' ','')
            name_start = curr_fn.find('=') + 1
            name_end = curr_fn.find('(')
            fn_names.append(curr_fn[name_start:name_end].lower())

        # Identify beginning of documentation. 
        # If function name is not in comment, no docs will be written.
        for i in range(a + 1, len(lines)):
            
            # Prevent 'see also' section matching value in fn_names and assigning 'a'.
            if lines[i].lstrip() and lines[i].lstrip()[0] != '%':
                prev_comment = False

            thisline = lines[i].replace('#', '')
            thisline = thisline.replace(' ', '')
            thisline = thisline.replace('%', '')
            thisline = thisline.strip()

            if thisline.lower() in fn_names and not prev_comment:
                is_class = True
                a = i
                break

    # Non-class files are slightly different. 
    # If filename is not in comment, no docs will be written. 
    else:
        for i in range(0, len(lines)):
            thisline = lines[i].replace('#', '')
            thisline = thisline.replace(' ', '')
            thisline = thisline.replace('%', '')
            thisline = thisline.strip()

            if thisline.lower() == filename.lower():
                a = i
                break

    # Find end of documentation.
    # Author must add 'end of documentation' before any code-specific comments within scripts. 
    if is_class:
        z_range_min = a
        
    for i in range(z_range_min, len(lines)):
        thisline = lines[i].strip().lower()

        # Using line of the last comment prevents capturing accidental newlines after description ends.
        if thisline.find('%') == 0 and thisline != '%' and 'end of documentation' not in thisline:
            lastcomment = i

        if (thisline.find('function') == 0 or 
            (thisline.find('%') != 0 and thisline) or 
            'end of documentation' in thisline 
            ):
            z = lastcomment + 1
            break

    if (a < 0 or z < 0) and not is_class:
        print(f"No documentation for {filename}. Skipping...")
        return

    # Write the documentation to out_file.
    if a > -1 and z > a:
        out_file.write('\n\n')

        if not first:
            out_file.write('-------\n\n')

        format_link = False

        for i in range(a, z):
            thisline = lines[i]
            thisline = thisline.replace('%}', '')
            thisline = thisline.strip(' %')
            thisline = thisline.lstrip()
            thisline = thisline.replace('XXXX', '    ')

            if not thisline:
                out_file.write('\n')
                continue

            # make the "see also" into a nice box
            if thisline.lower().find('see also') != -1:
                out_file.write('\n\n')
                thisline = '!!! info "See Also"\n'
                format_link = True
                out_file.write(thisline)
                continue

            # insert hyperlinks to other methods
            if thisline.find('* [') != -1 and format_link:
                # pre-formatted link, just write it
                out_file.write('    ' + thisline)

            elif '.' in thisline and format_link:
                # This is a class method
                words = thisline.split('.')
                link_class = words[0]
                link_method = words[1]

                if 'stimulus_generation' not in file:
                    out_file.write(f'    * [{thisline.strip()}]' +
                                f'(../stimgen/{link_class}/#' + 
                                f'{link_method.strip().lower()})\n')
              
                else:
                    out_file.write('    * [' + thisline.strip() + '](../' +
                                link_class + '/#' + link_method.strip().lower() + ')\n')

            elif format_link:
                # This is a reference to a standalone function or script

                # Find file being referred to. 
                # Some wrangling to always write proper path relative to current file.
                # Path written as though `tinnitus-reconstruction/code` is current directory. 
                ref = [item for item in glob(f'{root_pth}/code/**/*.m', recursive=True) 
                        if thisline.strip() == os.path.basename(item)[:-2]]
                
                # Catch empty ref
                if not ref:
                    print(f"[WARN]: 'See also' not formatted properly in {filename} line {i}.")
                    continue

                # Get path to /code
                if root_pth == '.':
                    ref_pth = ref[0][7:]
                else:
                    ref_pth = ref[0][ref[0].find('tinnitus-reconstruction'):].replace('tinnitus-reconstruction/code/','')

                # Format it and write it
                if os.path.dirname(ref[0]) == os.path.dirname(file):
                    out_file.write(f'    * [{thisline.strip()}]' + 
                                f'(./#{thisline.strip().lower()})\n')

                elif 'stimulus_generation' in file:
                    out_file.write(f'    * [{thisline.strip()}]' + 
                                f'(../../{os.path.dirname(ref_pth)}/#{thisline.strip().lower()})\n')

                else:
                    out_file.write(f'    * [{thisline.strip()}]' + 
                                f'(../{os.path.dirname(ref_pth)}/#{thisline.strip().lower()})\n')

            else:
                out_file.write(thisline)

        out_file.write('\n\n\n')

    # Recursion for multiple functions within classes.
    if is_class and a < fns[-1][0]:
        comment2docs(filename, file, out_file, False, root_pth, a)

    out_file.close()

if __name__ == '__main__':
    comment2docs()