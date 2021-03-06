
!    This file is part of STATAMOD. Copyright (c) 2006-2009 Andrew Shephard
!
!    STATAMOD is free software: you can redistribute it and/or modify
!    it under the terms of the GNU General Public License as published by
!    the Free Software Foundation, either version 3 of the License, or
!    (at your option) any later version.
!
!    STATAMOD is distributed in the hope that it will be useful,
!    but WITHOUT ANY WARRANTY; without even the implied warranty of
!    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
!    GNU General Public License for more details.
!
!    You should have received a copy of the GNU General Public License
!    along with STATAMOD.  If not, see <http://www.gnu.org/licenses/>.

module stataMod

    implicit none

    private
    
    !public access
    public :: saveStata, closeSaveStata, writestata
    public :: writeStataInt4, writeStataInt2, writeStataInt1,writeStataReal4, writeStataReal8              
    public :: maxST_byte, maxST_int, maxST_long, maxST_float, maxST_double
    
    !data types
    integer, parameter :: sp = selected_real_kind(6,30)
    integer, parameter :: dp = selected_real_kind(15,100)
    integer, parameter :: i4 = selected_int_kind(5)
    integer, parameter :: i2 = selected_int_kind(3)
    integer, parameter :: i1 = selected_int_kind(1)
    
    integer,  parameter :: maxST_byte   = 100
    integer,  parameter :: maxST_int    = 32740
    integer,  parameter :: maxST_long   = 2147483620
    real(sp), parameter :: maxST_float  = Z'7effffff'         !approx +1.701e+38 
    real(dp), parameter :: maxST_double = Z'7fdfffffffffffff' !approx +8.988e+307

    type :: position
        integer :: start
        integer, dimension(:), allocatable :: offset
        integer :: nvaroffset
    end type position
    
    type stcell !use linked list when saving
        real(dp),    dimension(:), allocatable :: valReal8
        real(sp),    dimension(:), allocatable :: valReal4
        integer(i4), dimension(:), allocatable :: valInt4
        integer(i2), dimension(:), allocatable :: valInt2
        integer(i1), dimension(:), allocatable :: valInt1
        integer(i2)                            :: valType
        character(33)                          :: name
        character(81)                          :: label
        type(stcell), pointer                  :: next
    end type stcell
        
    type :: stata
    
        ! file header
        integer(i1)   :: ds_format
        integer(i1)   :: byteorder
        integer(i1)   :: filetype
        integer(i2)   :: nvar
        integer(i4)   :: nobs
        character(81) :: data_label
        character(18) :: time_stamp

        ! descriptors
        integer(i2),   dimension(:), allocatable :: typlist
        character(33), dimension(:), allocatable :: varlist
        integer(i2),   dimension(:), allocatable :: srtlist
        character(49), dimension(:), allocatable :: fmtlist
        character(33), dimension(:), allocatable :: lbllist

        !variable labels          
        character(81), dimension(:),   allocatable :: varlabl  
        character(1),  dimension(:,:), allocatable :: thesedata !enitre data if cached

        integer :: unit  !unit number
        logical :: cache !cache data?
        logical :: init = .false. !initialised?
        
        type(position) :: stataPosition  !file position

        ! the remaining information is for when Stata files are written
        
        integer(i4) :: saveDim   !array dim size
        integer(i4) :: saveUnit  !unit number
        integer(i4) :: saveNObs  !save observations
        integer(i2) :: saveNVar  !save variables
        
        logical :: saveInit = .false. !initialised?
        logical :: saveOnce  !has a variable been written?
        logical :: saveCache !save cache?
        logical :: saveCompress !compress dataset
        
        character(81) :: saveLabel !dataset label
        character(18) :: saveTime  !time stamp
        
        type(stcell), pointer :: saveCurr, saveHead
        
    end type stata

    type(stata), save :: statafile

    interface writestata
        module procedure writeStataInt1
        module procedure writeStataInt2
        module procedure writeStataInt4
        module procedure writeStataReal4
        module procedure writeStataReal8
    end interface writestata
    
   
        
contains     
    
    subroutine saveStata(fileName,thisUnit,obs,label)
    
        implicit none
        
        character(*),  intent(in)           :: fileName
        integer(i4),   intent(in)           :: thisUnit
        integer(i4),   intent(in)           :: obs
        character(*),  intent(in), optional :: label

        integer(i1) :: tempInt1  
        integer(i4) :: ios
        
        if (stataFile%saveInit) then
            call statamodError('A file has already been specified for saving')
        end if
    
        if (obs < 1) then
            call statamodError('Expecting at least one observation to be declared')
        end if
            
        stataFile%saveUnit = thisUnit
        stataFile%saveNObs = obs            
        stataFile%saveNVar = 0
        stataFile%saveOnce = .false.            
        stataFile%saveTime = dateStata()
        
        if (present(label)) then
            tempInt1 = len(label) + 1
            stataFile%saveLabel = label
            stataFile%saveLabel(tempInt1:81) = char(0)                
        else
            stataFile%saveLabel = char(0)
        end if
                    
        open(stataFile%saveUnit,FILE=fileName,ACTION='write',STATUS='REPLACE',access='stream',form='unformatted',IOSTAT=ios)
        
        if (ios /= 0) then
            call statamodError('error saving file '//fileName)
        end if
        
        !save as stata 7 s/e
        write(stataFile%saveUnit, IOSTAT=ios) 111_i1 ! Stata 7 S/E
        write(stataFile%saveUnit, IOSTAT=ios) 2_i1   ! byte order
        write(stataFile%saveUnit, IOSTAT=ios) 1_i1   ! filetype
        write(stataFile%saveUnit, IOSTAT=ios) 0_i1   ! junk
        
        if (ios /= 0) then
            call statamodError('error writing file header')
        end if
        
        stataFile%saveInit = .true.
        stataFile%saveDim  = 0
        
    end subroutine saveStata

    subroutine writeStataReal4(thisVar, thisName, thisLabel)
        
        implicit none
        
        real(sp), dimension(:), intent(in) :: thisVar    
                                    
        include 'writestata1.inc'            
                    
        ! var type
        stataFile%saveCurr%valType = 254
        stataFile%saveDim = stataFile%saveDim + 4
        
        ! copy contents
        allocate(stataFile%saveCurr%valReal4(stataFile%saveNObs), STAT=ios)
        
        if (ios /= 0) then
            call statamodError('error allocating memory')
        end if
        
        stataFile%saveCurr%valReal4 = thisVar
        
        include 'writestata2.inc'            
        
    end subroutine writeStataReal4
    
    subroutine writeStataReal8(thisVar, thisName, thisLabel)
        
        implicit none
        
        real(dp), dimension(:), intent(in) :: thisVar    
                    
        include 'writestata1.inc'
                                
        ! var type
        stataFile%saveCurr%valType = 255
        stataFile%saveDim = stataFile%saveDim + 8
        
        ! copy contents
        allocate(stataFile%saveCurr%valReal8(stataFile%saveNObs), STAT=ios)
        
        if (ios /= 0) then
            call statamodError('error allocating memory')
        end if
        
        stataFile%saveCurr%valReal8 = thisVar
        
        include 'writestata2.inc'            
        
    end subroutine writeStataReal8
    
    subroutine writeStataInt1(thisVar, thisName, thisLabel)
        
        implicit none
        
        integer(i1), dimension(:), intent(in) :: thisVar    
            
        include 'writestata1.inc'            
                    
        ! var type
        stataFile%saveCurr%valType = 251
        stataFile%saveDim = stataFile%saveDim + 1
        
        ! copy contents
        allocate(stataFile%saveCurr%valInt1(stataFile%saveNObs), STAT=ios)
        
        if (ios /= 0) then
            call statamodError('error allocating memory')
        end if
        
        stataFile%saveCurr%valInt1 = thisVar
        
        include 'writestata2.inc'
                    
    end subroutine writeStataInt1
    
    subroutine writeStataInt2(thisVar, thisName, thisLabel)
        
        implicit none
        
        integer(i2), dimension(:), intent(in) :: thisVar    
                    
        include 'writestata1.inc'
                    
        ! var type
        stataFile%saveCurr%valType = 252
        stataFile%saveDim = stataFile%saveDim + 2
        
        ! copy contents
        allocate(stataFile%saveCurr%valInt2(stataFile%saveNObs), STAT=ios)
        
        if (ios /= 0) then
            call statamodError('error allocating memory')
        end if
        
        stataFile%saveCurr%valInt2 = thisVar
                                
        include 'writestata2.inc'            
        
    end subroutine writeStataInt2
    
    subroutine writeStataInt4(thisVar, thisName, thisLabel)
        
        implicit none
        
        integer(i4), dimension(:), intent(in) :: thisVar    
            
        include 'writestata1.inc'
                    
        ! var type
        stataFile%saveCurr%valType = 253
        stataFile%saveDim = stataFile%saveDim + 4
        
        ! copy contents
        allocate(stataFile%saveCurr%valInt4(stataFile%saveNObs), STAT=ios)
        
        if (ios /= 0) then
            call statamodError('error allocating memory')
        end if
        
        stataFile%saveCurr%valInt4 = thisVar
        
        include 'writestata2.inc'            
        
    end subroutine writeStataInt4
    
    subroutine closeSaveStata(cache)
    
        implicit none
    
        logical, optional :: cache
        
        integer(i4)  :: ios, tempInt4, i, j
        character(1) :: unsignedByte !unsigned integers are not supported. use this as work around
        
        integer(i1),   dimension(2*(stataFile%saveNVar+1)) :: srtlist
        character(12), dimension(stataFile%saveNVar)       :: fmtlist
        character(33), dimension(stataFile%saveNVar)       :: lbllist
                    
        integer(i1), dimension(5)   :: expfield
        
        character(stataFile%saveDim), allocatable, dimension(:) :: dataset
        
        if (.not. stataFile%saveInit) then
            call statamodError('no file have been specified for saving')
        end if
        
        write(stataFile%saveUnit, IOSTAT=ios) stataFile%saveNVar  !Variables
        write(stataFile%saveUnit, IOSTAT=ios) stataFile%saveNObs  !Observations
        write(stataFile%saveUnit, IOSTAT=ios) stataFile%saveLabel !Label            
        write(stataFile%saveUnit, IOSTAT=ios) stataFile%saveTime  !time stamp
        
        if (ios /= 0) then
            call statamodError('error writing file specific header information')
        end if
        
        ! write descriptors
        
        ! typlist
        stataFile%saveCurr => stataFile%saveHead
        tempInt4 = 0
        
        do i = 1, stataFile%saveNVar            
            unsignedByte = char(stataFile%saveCurr%valType) !work around
            write(stataFile%saveUnit, IOSTAT=ios) unsignedByte
            stataFile%saveCurr => stataFile%saveCurr%next
        end do !i

        ! varlist   
        stataFile%saveCurr => stataFile%saveHead
        
        do i = 1, stataFile%saveNVar
            write(stataFile%saveUnit, IOSTAT=ios) stataFile%saveCurr%name
            stataFile%saveCurr => stataFile%saveCurr%next
        end do !i
                    
        ! srtlist (unsorted)
        srtlist = 0
        write(stataFile%saveUnit, IOSTAT=ios) srtlist
        
        ! fmtlist (use default stata format)
        fmtlist = '%8.0g'//char(0)
        write(stataFile%saveUnit, IOSTAT=ios) fmtlist
        
        ! lbllist
        lbllist = char(0)
        write(stataFile%saveUnit, IOSTAT=ios) lbllist
        
        if (ios /= 0) then
            call statamodError('error writing descriptors')
        end if
        
        ! write variable labels
        
        stataFile%saveCurr => stataFile%saveHead
        
        do i = 1, stataFile%saveNVar
            write(stataFile%saveUnit, IOSTAT=ios) stataFile%saveCurr%label
            stataFile%saveCurr => stataFile%saveCurr%next
        end do !i
        
        if (ios /= 0) then
            call statamodError('error writing variable labels')
        end if
        
        ! write expansion fields
        
        expfield = 0
        write(stataFile%saveUnit, IOSTAT=ios) expfield
        
        if (ios /= 0) then
            call statamodError('error writing expansion fields')
        end if
        
        ! write actual variables      

        if (present(cache)) then
            stataFile%saveCache = cache
        else
            stataFile%saveCache = .true.
        end if
        
        if (stataFile%saveCache) then            
        
            ! because the data is of potentially different types, we must construct
            ! an appropriately sized character array and use the transfer function
            ! to copy exact bit pattern
                    
            allocate(dataset(stataFile%saveNObs), STAT=ios)
                    
            if (ios /= 0) then
                call statamodError('error allocating memory for variable writing. Use closeSaveStata(.false.).')
            end if
        
            stataFile%saveCurr => stataFile%saveHead
            tempInt4 = 1
            
            do i = 1, stataFile%saveNVar

                select case(stataFile%saveCurr%valType)
                    case(251_i2)   !ST_byte               
                        dataset(:)(tempInt4:tempInt4)   = transfer(stataFile%saveCurr%valInt1,(/1_'0'/))
                        tempInt4 = tempInt4 + 1
                    case(252_i2)   !ST_int
                        dataset(:)(tempInt4:tempInt4+1) = transfer(stataFile%saveCurr%valInt2,(/1_'00'/))
                        tempInt4 = tempInt4 + 2
                    case(253_i2)   !ST_long
                        dataset(:)(tempInt4:tempInt4+3) = transfer(stataFile%saveCurr%valInt4,(/1_'0000'/))
                        tempInt4 = tempInt4 + 4
                    case(254_i2)   !ST_float
                        dataset(:)(tempInt4:tempInt4+3) = transfer(stataFile%saveCurr%valReal4,(/1_'0000'/))
                        tempInt4 = tempInt4 + 4
                    case(255_i2)   !ST_double
                        dataset(:)(tempInt4:tempInt4+7) = transfer(stataFile%saveCurr%valReal8,(/1_'00000000'/))
                        tempInt4 = tempInt4 + 8
                    case default
                        call statamodError('unknown data type')
                end select

                stataFile%saveCurr => stataFile%saveCurr%next

            end do !i
            
            write(stataFile%saveUnit, IOSTAT=ios) dataset
        
        else
        
            do i = 1, stataFile%saveNObs
            
                stataFile%saveCurr => stataFile%saveHead
                            
                do j = 1, stataFile%saveNVar

                    select case(stataFile%saveCurr%valType)
                        case(251_i2)   !ST_byte               
                            write(stataFile%saveUnit,IOSTAT=ios) stataFile%saveCurr%valInt1(i:i)
                        case(252_i2)   !ST_int
                            write(stataFile%saveUnit,IOSTAT=ios) stataFile%saveCurr%valInt2(i:i)
                        case(253_i2)   !ST_long
                            write(stataFile%saveUnit,IOSTAT=ios) stataFile%saveCurr%valInt4(i:i)
                        case(254_i2)   !ST_float
                            write(stataFile%saveUnit,IOSTAT=ios) stataFile%saveCurr%valReal4(i:i)
                        case(255_i2)   !ST_double
                            write(stataFile%saveUnit,IOSTAT=ios) stataFile%saveCurr%valReal8(i:i)
                        case default
                            call statamodError('unknown data type')
                    end select

                stataFile%saveCurr => stataFile%saveCurr%next

                end do !j
            
            end do !i
            
        end if
        
        if (ios /= 0) then
            call statamodError('error writing actual data contents')
        end if
                    
        ! deallocate memory and close file

        stataFile%saveCurr => stataFile%saveHead
    
        do while(associated(stataFile%saveCurr))
            stataFile%saveHead => stataFile%saveCurr%next
            deallocate(stataFile%saveCurr, STAT=ios)
            if (ios /= 0) call statamodWarn('error deallocating memory')
            stataFile%saveCurr => stataFile%saveHead
        end do

        stataFile%saveInit = .false.            
        
        if (stataFile%saveCache) then
            deallocate(dataset)
        end if
        
        close(stataFile%saveUnit)

        call statamodMsg('STATA file successfully saved')
                    
    end subroutine closeSaveStata
    
                            
    
    
    character(3) function versionStata(version) !return string with STATA version number
    
        implicit none
        
        integer(i1), intent(in) :: version
        
        select case(version)
            case(114_i1)
                versionStata = '10'
            case(113_i1)
                versionStata = '8'
            case(111_i1)
                versionStata = '7SE'
            case(110_i1)
                versionStata = '7'
            case(108_i1)
                versionStata = '6'
            case(105_i1)
                versionStata = '5'
            case default
                versionStata = '?'  
        end select
        
    end function versionStata   
    
    integer(i2) function varno(varname) !return variable number corresponding to varname
        
        implicit none
        
        character(*), intent(in) :: varname
        integer(i4)              :: i
            
        varno = 0

        do i = 1, stataFile%nvar
            if (varname == stataFile%varlist(i)) then
                varno = i
                exit
            end if
        end do
        
    end function varno
    
    character(18) function dateStata()
        
        implicit none

        character(18) :: date_time(2)
        character(3)  :: this_month
                            
        call date_and_time(date_time(1), date_time(2))
        
        select case(date_time(1)(5:6))
            case('01')
                this_month = 'Jan'
            case('02')
                this_month = 'Feb'
            case('03')
                this_month = 'Mar'
            case('04')
                this_month = 'Apr'
            case('05')
                this_month = 'May'
            case('06')
                this_month = 'Jun'
            case('07')
                this_month = 'Jul'
            case('08')
                this_month = 'Aug'
            case('09')
                this_month = 'Sep'
            case('10')
                this_month = 'Oct'
            case('11')
                this_month = 'Nov'
            case('12')
                this_month = 'Dec'
            case default
                this_month = '???'
        end select
        
        dateStata = date_time(1)(7:8)//' '//this_month//' '//date_time(1)(1:4)//' '//date_time(2)(1:2)//':'//date_time(2)(3:4)
        dateStata(18:18) = char(0)
        
    end function dateStata

    subroutine statamodError(errmsg,funit)

        implicit none

        character(*),      intent(in) :: errmsg
        integer, optional, intent(in) :: funit
        
        if (present(funit)) then
            write (funit,*) 'STATAMOD ERROR: ',errmsg
            stop 'program terminated by statamodError'
        else
            write (*,*) 'STATAMOD ERROR: ',errmsg
            stop 'program terminated by statamodError'
        end if

        return

    end subroutine statamodError

    subroutine statamodWarn(warnmsg,funit)
    
        character(*),      intent(in) :: warnmsg
        integer, optional, intent(in) :: funit
        
        if (present(funit)) then
            write (funit,*) 'STATAMOD WARNING: ', warnmsg
        else
            write (*,*) 'STATAMOD WARNING: ', warnmsg
        end if

        return

    end subroutine statamodWarn

    subroutine statamodMsg(msg,funit)
    
        character(*),      intent(in) :: msg
        integer, optional, intent(in) :: funit
        
        if (present(funit)) then
            write (funit,*) 'STATAMOD: ', msg
        else
            write (*,*) 'STATAMOD: ', msg
        end if

        return

    end subroutine statamodMsg
            
end module stataMod
