/* -*- ld-script -*- */

/*
 * Linker script for i386 images
 *
 */

SECTIONS {

    /* Each section starts at a virtual address of zero.
     *
     * We guarantee alignment of virtual addresses to any alignment
     * specified by the constituent object files (e.g. via
     * __attribute__((aligned(x)))).  Load addresses are guaranteed
     * only up to _max_align.  Provided that all loader and relocation
     * code honours _max_align, this means that physical addresses are
     * also guaranteed up to _max_align.
     *
     * Note that when using -DKEEP_IT_REAL, the UNDI segments are only
     * guaranteed to be loaded on a paragraph boundary (i.e. 16-byte
     * alignment).  Using _max_align>16 will therefore not guarantee
     * >16-byte alignment of physical addresses when -DKEEP_IT_REAL is
     * used (though virtual addresses will still be fully aligned).
     *
     */

    PROVIDE ( _max_align = 16 );

    /*
     * Values used in page table calculations
     *
     * On older versions of ld (without the SANE_EXPR feature),
     * numeric literals within a section description tend to be
     * interpreted as section-relative symbols.
     *
     */
    _page_size = 4096;
    _page_size_1 = ( _page_size - 1 );
    _pte_size = 8;
    _pte_count = ( _page_size / _pte_size );
    _pte_count_1 = ( _pte_count - 1 );

    /*
     * Allow decompressor to require a minimum amount of temporary stack
     * space.
     *
     */
    PROVIDE ( _min_decompress_stack = 0 );

    /*
     * The prefix
     *
     */

    .prefix 0x0 : AT ( _prefix_lma ) {
	_prefix = .;
	*(.prefix)
	*(SORT(.pci_devlist.*))
	*(.prefix.*)
	_mprefix = .;
    } .bss.prefix (NOLOAD) : AT ( _bss_prefix_lma ) {
	_eprefix = .;
    }
    _prefix_filesz	= ABSOLUTE ( _mprefix ) - ABSOLUTE ( _prefix );
    _prefix_memsz	= ABSOLUTE ( _eprefix ) - ABSOLUTE ( _prefix );
    _prefix_padsz	= ABSOLUTE ( _eprefix ) - ABSOLUTE ( _mprefix );

    /*
     * The 16-bit (real-mode) code section
     *
     */

    .text16.early 0x0 : AT ( _text16_early_lma ) {
	_text16 = .;
	KEEP(*(.text16.null))
	KEEP(*(.text16.null.*))
	. += 1;				/* Prevent NULL being valid */
	*(.text16.early)
	*(.text16.early.*)
	_etext16_early = .;
    } .text16.late ALIGN ( _max_align ) : AT ( _text16_late_lma ) {
	_text16_late = .;
	*(.text16)
	*(.text16.*)
	_mtext16 = .;
    } .bss.text16 (NOLOAD) : AT ( _bss_text16_lma ) {
	_etext16 = .;
    }
    _text16_early_filesz = ABSOLUTE ( _etext16_early ) - ABSOLUTE ( _text16 );
    _text16_early_memsz	= ABSOLUTE ( _etext16_early ) - ABSOLUTE ( _text16 );
    _text16_late_filesz	= ABSOLUTE ( _mtext16 ) - ABSOLUTE ( _text16_late );
    _text16_late_memsz	= ABSOLUTE ( _etext16 ) - ABSOLUTE ( _text16_late );
    _text16_memsz	= ABSOLUTE ( _etext16 ) - ABSOLUTE ( _text16 );
    _text16_padsz	= ABSOLUTE ( _etext16 ) - ABSOLUTE ( _mtext16 );

    /*
     * The 16-bit (real-mode) data section
     *
     */

    .data16 0x0 : AT ( _data16_lma ) {
	_data16 = .;
	. += 1;				/* Prevent NULL being valid */
	*(.rodata16)
	*(.rodata16.*)
	*(.data16)
	*(.data16.*)
	_mdata16 = .;
    } .bss.data16 (NOLOAD) : AT ( _bss_data16_lma ) {
	*(.bss16)
	*(.bss16.*)
	*(.stack16)
	*(.stack16.*)
	. = MAX ( ., _mdata16 + _min_decompress_stack );
	_edata16 = .;
    }
    _data16_filesz	= ABSOLUTE ( _mdata16 ) - ABSOLUTE ( _data16 );
    _data16_memsz	= ABSOLUTE ( _edata16 ) - ABSOLUTE ( _data16 );
    _data16_padsz	= ABSOLUTE ( _edata16 ) - ABSOLUTE ( _mdata16 );

    /*
     * The 32-bit sections
     *
     */

    .textdata 0x0 : AT ( _textdata_lma ) {
	_textdata = .;
	KEEP(*(.text.null_trap))
	KEEP(*(.text.null_trap.*))
	. += 1;				/* Prevent NULL being valid */
	*(.text)
	*(.text.*)
	*(.srodata)
	*(.srodata.*)
	*(.rodata)
	*(.rodata.*)
	*(.sdata)
	*(.sdata.*)
	*(.data)
	*(.data.*)
	KEEP(*(SORT(.tbl.*)))	/* Various tables.  See include/tables.h */
	KEEP(*(.provided))
	KEEP(*(.provided.*))
	_mtextdata = .;
    } .bss.textdata (NOLOAD) : AT ( _bss_textdata_lma ) {
	*(.sbss)
	*(.sbss.*)
	*(.bss)
	*(.bss.*)
	*(COMMON)
	*(.stack)
	*(.stack.*)
	_pages = .;
	*(.pages)
	*(.pages.*)
	_use_page_tables = ABSOLUTE ( . ) - ABSOLUTE ( _pages );
	_textdata_paged_len =
	    ABSOLUTE ( ABSOLUTE ( . ) - ABSOLUTE ( _textdata ) );
	_textdata_ptes =
	    ABSOLUTE ( ( _textdata_paged_len + _page_size_1 ) / _page_size );
	_textdata_pdes =
	    ABSOLUTE ( ( _textdata_ptes + _pte_count_1 ) / _pte_count );
	. += ( _use_page_tables ? ( _textdata_pdes * _page_size ) : 0 );
	_epages = .;
	_etextdata = .;
    }
    _textdata_filesz	= ABSOLUTE ( _mtextdata ) - ABSOLUTE ( _textdata );
    _textdata_memsz	= ABSOLUTE ( _etextdata ) - ABSOLUTE ( _textdata );
    _textdata_padsz	= ABSOLUTE ( _etextdata ) - ABSOLUTE ( _mtextdata );

    /*
     * Payload prefix
     *
     * If present, this will be placed between .text16.early and .text16.late.
     *
     */
    .pprefix 0x0 : AT ( _pprefix_lma ) {
	_pprefix = .;
	KEEP(*(.pprefix))
	KEEP(*(.pprefix.*))
	_mpprefix = .;
    } .bss.pprefix (NOLOAD) : AT ( _bss_pprefix_lma ) {
	_epprefix = .;
    }
    _pprefix_filesz	= ABSOLUTE ( _mpprefix ) - ABSOLUTE ( _pprefix );
    _pprefix_memsz	= ABSOLUTE ( _epprefix ) - ABSOLUTE ( _pprefix );
    _pprefix_padsz	= ABSOLUTE ( _epprefix ) - ABSOLUTE ( _mpprefix );

    /*
     * Compressor information block
     *
     */

    .zinfo 0x0 : AT ( _zinfo_lma ) {
	_zinfo = .;
	KEEP(*(.zinfo))
	KEEP(*(.zinfo.*))
	_mzinfo = .;
    } .bss.zinfo (NOLOAD) : AT ( _bss_zinfo_lma ) {
	_ezinfo = .;
    }
    _zinfo_filesz	= ABSOLUTE ( _mzinfo ) - ABSOLUTE ( _zinfo );
    _zinfo_memsz	= ABSOLUTE ( _ezinfo ) - ABSOLUTE ( _zinfo );
    _zinfo_padsz	= ABSOLUTE ( _ezinfo ) - ABSOLUTE ( _mzinfo );

    /*
     * Weak symbols that need zero values if not otherwise defined
     *
     */

    .weak 0x0 : AT ( _end_lma ) {
	_weak = .;
	*(.weak)
	*(.weak.*)
	_eweak = .;
    }
    _assert = ASSERT ( ( _weak == _eweak ), ".weak is non-zero length" );

    /*
     * Dispose of the comment and note sections to make the link map
     * easier to read
     *
     */

    /DISCARD/ : {
	*(.comment)
	*(.comment.*)
	*(.note)
	*(.note.*)
	*(.eh_frame)
	*(.eh_frame.*)
	*(.rel)
	*(.rel.*)
	*(.einfo)
	*(.einfo.*)
	*(.discard)
	*(.discard.*)
	*(.sbat)
	*(.sbat.*)
    }

    /*
     * Load address calculations.  In older versions of ld, ALIGN()
     * can operate only on the location counter, so we use that.
     *
     */

    .			= 0;

    .			= ALIGN ( _max_align );
    _prefix_lma		= .;
    .			+= ABSOLUTE ( _prefix_filesz );

    .			= ALIGN ( _max_align );
    _text16_early_lma	= .;
    .			+= ABSOLUTE ( _text16_early_filesz );

    .			= ALIGN ( _max_align );
    .			= ALIGN ( _payload_align );
    _pprefix_lma	= .;
    .			+= ABSOLUTE ( _pprefix_filesz );

    .			= ALIGN ( _max_align );
    _payload_lma	= .;
    _pprefix_skip	= ABSOLUTE ( _payload_lma ) - ABSOLUTE ( _pprefix_lma );
    _text16_late_lma	= .;
    .			+= ABSOLUTE ( _text16_late_filesz );

    .			= ALIGN ( _max_align );
    _data16_lma		= .;
    .			+= ABSOLUTE ( _data16_filesz );

    .			= ALIGN ( _max_align );
    _textdata_lma	= .;
    .			+= ABSOLUTE ( _textdata_filesz );

    _filesz		= .; /* Do not include .bss.* or .zinfo in file size */

    /*
     * Dummy load addresses for .bss.* and .zinfo sections
     *
     */

    .			= ALIGN ( _max_align );
    _bss_prefix_lma	= .;
    .			+= ABSOLUTE ( _prefix_padsz );

    .			= ALIGN ( _max_align );
    _bss_text16_lma	= .;
    .			+= ABSOLUTE ( _text16_padsz );

    .			= ALIGN ( _max_align );
    _bss_data16_lma	= .;
    .			+= ABSOLUTE ( _data16_padsz );

    .			= ALIGN ( _max_align );
    _bss_textdata_lma	= .;
    .			+= ABSOLUTE ( _textdata_padsz );

    .			= ALIGN ( _max_align );
    _bss_pprefix_lma	= .;
    .			+= ABSOLUTE ( _pprefix_padsz );

    .			= ALIGN ( _max_align );
    _bss_zinfo_lma	= .;
    .			+= ABSOLUTE ( _zinfo_padsz );

    .			= ALIGN ( _max_align );
    _zinfo_lma		= .;
    .			+= ABSOLUTE ( _zinfo_filesz );

    .			= ALIGN ( _max_align );
    _end_lma		= .;

    /*
     * Values calculated to save code from doing it
     *
     */
    _text16_memsz_ppgh	= ( ( ( _text16_memsz + 63 ) / 64 ) * 4 );
    _data16_memsz_ppgh	= ( ( ( _data16_memsz + 63 ) / 64 ) * 4 );
    _textdata_memsz_pgh	= ( ( _textdata_memsz + 15 ) / 16 );
    _textdata_memsz_kb	= ( ( _textdata_memsz + 1023 ) / 1024 );
}
