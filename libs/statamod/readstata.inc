
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

integer(i1) :: tempST_byte
integer(i2) :: tempST_int
integer(i4) :: tempST_long
real(sp)    :: tempST_float
real(dp)    :: tempST_double
                                                  
integer(i4) :: i, thisVarno, filePointer, varStart, sizeReadStata

if (.not. stataFile%init) then
    call statamodError('STATA file is not open')
end if

!remove whitespace and find index
thisVarno = varno(trim(adjustl(varname)))

if (thisVarno==0) then
    call statamodWarn('variable '//trim(adjustl(varname))//' does not exist')
    readStataVar = 0
    return
end if

sizeReadStata = size(readStataVar)

if (sizeReadStata.lt.stataFile%nobs) then
    call statamodWarn('number of observations exceeds array storage')
end if

!for access from memory

if (stataFile%cache) then

    varStart = stataFile%stataPosition%offset(thisVarno) + 1 !column location of varname
   
    !if (sizeReadStata==stataFile%nobs) then
        !use transfer intrinsic to cast data
        select case(stataFile%typlist(thisVarno))
            case(1_i2:244_i2) !str
                call statamodWarn('strings are not supported; setting array to zero')
                readStataVar = 0
            case(251_i2)   !ST_byte               
                readStataVar = transfer(stataFile%theseData(varStart:varStart,:),(/0_i1/))
            case(252_i2)   !ST_int
                readStataVar = transfer(stataFile%theseData(varStart:(varStart+1),:),(/0_i2/))
            case(253_i2)   !ST_long
                readStataVar = transfer(stataFile%theseData(varStart:(varStart+3),:),(/0_i4/))
            case(254_i2)   !ST_float
                readStataVar = transfer(stataFile%theseData(varStart:(varStart+3),:),(/0.0_sp/))
            case(255_i2)   !ST_double
                readStataVar = transfer(stataFile%theseData(varStart:(varStart+7),:),(/0.0_dp/))
            case default
                call statamodWarn('unknown data type; setting array to zero')
                readStataVar = 0
        end select
    !end if

else !disk access... can be slow but doesn't require as much memory
            
    !move file pointer to start of data

    filePointer = FSEEK(stataFile%unit,stataFile%stataPosition%start,0)
    filePointer = FSEEK(stataFile%unit,stataFile%stataPosition%offset(thisVarno),1)

    if (filePointer/=0) then
        call statamodError('error moving file pointer')
        !write (6,*)  'STATAMOD ERROR: error moving file pointer'
        !stop
    end if
    
    select case(stataFile%typlist(thisVarno))
        case(1_i2:244_i2) !str
            call statamodWarn('strings are not supported; setting array to zero')
            readStataVar = 0    
        case(251_i2)   !ST_byte             
            do i=1, min(sizeReadStata,stataFile%nobs)
                read(stataFile%unit) tempST_byte
                readStataVar(i:i)  = tempST_byte
                filePointer = FSEEK(stataFile%unit,stataFile%stataPosition%nvarOffset - 1,1)      
            end do                    
        case(252_i2)   !ST_int
            do i=1, min(sizeReadStata,stataFile%nobs)
                read(stataFile%unit) tempST_int
                readStataVar(i:i)  = tempST_int
                filePointer = FSEEK(stataFile%unit,stataFile%stataPosition%nvarOffset - 2,1)      
            end do   
        case(253_i2)   !ST_long
            do i=1, min(sizeReadStata,stataFile%nobs)
                read(stataFile%unit) tempST_long
                readStataVar(i:i)  = tempST_long
                filePointer = FSEEK(stataFile%unit,stataFile%stataPosition%nvarOffset - 4,1)      
            end do
        case(254_i2)   !ST_float
            do i=1, min(sizeReadStata,stataFile%nobs)
                read(stataFile%unit) tempST_float
                readStataVar(i:i)  = tempST_float
                filePointer = FSEEK(stataFile%unit,stataFile%stataPosition%nvarOffset - 4,1)      
            end do                         
        case(255_i2)   !ST_double
            do i=1, min(sizeReadStata,stataFile%nobs)
                read(stataFile%unit) tempST_double
                readStataVar(i:i)  = tempST_double
                filePointer = FSEEK(stataFile%unit,stataFile%stataPosition%nvarOffset - 8,1)      
            end do                        
        case default
            call statamodWarn('unknown data type; setting array to zero')
            readStataVar = 0
    end select 
                
end if
