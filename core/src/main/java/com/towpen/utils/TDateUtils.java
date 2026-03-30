package com.towpen.utils;

import com.towpen.base.exceptions.TOpenValidationException;
import lombok.experimental.UtilityClass;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javax.xml.datatype.DatatypeConfigurationException;
import javax.xml.datatype.DatatypeConstants;
import javax.xml.datatype.DatatypeFactory;
import javax.xml.datatype.XMLGregorianCalendar;
import java.text.DateFormat;
import java.text.DecimalFormat;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.time.*;
import java.time.format.DateTimeFormatter;
import java.time.temporal.ChronoUnit;
import java.time.temporal.TemporalAdjusters;
import java.util.Calendar;
import java.util.Date;
import java.util.GregorianCalendar;

@UtilityClass
public class TDateUtils {

	public static final String DEFAULT_DATE = "dd/MM/yyyy";
	public static final DecimalFormat DECIMAL_FORMAT = new DecimalFormat("00");
	final static Logger logger = LoggerFactory.getLogger(TDateUtils.class);

	public static XMLGregorianCalendar toXMLGregorianCalendar(Date date) {

		XMLGregorianCalendar xmlDate = null;
		GregorianCalendar gc = new GregorianCalendar();
		gc.setTime(date);
		try {
			xmlDate = DatatypeFactory.newInstance().newXMLGregorianCalendar(gc);

		} catch (Exception e) {
			e.printStackTrace();
		}

		return xmlDate;
	}

	public static int getLastDayOfMonthUsingTemporalAdjusters(LocalDate date) {
		return date.with(TemporalAdjusters.lastDayOfMonth()).getDayOfMonth();
	}

	public static boolean isLastDayOfMonth(LocalDate date) {
		return date.getDayOfMonth() == getLastDayOfMonthUsingTemporalAdjusters(date);
	}

	public static boolean isLeapYear(LocalDate date) {
		return date.isLeapYear();
	}

	public static void main(String[] args) {
		LocalDate d = LocalDate.of(2025, 2, 22);
		d.isLeapYear();
		System.out.println(getLastDayOfMonthUsingTemporalAdjusters(d));

	}

	public static Date fromStringToDate(String dateStr, String datePattern) {
		DateFormat fm = new SimpleDateFormat(datePattern);
		try {
			return fm.parse(dateStr);
		} catch (ParseException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		return null;

	}

	public static XMLGregorianCalendar toXMLGregorianCalendarNoTimezone(Date date) {

		XMLGregorianCalendar xmlDate = toXMLGregorianCalendar(date);

		xmlDate.setTimezone(DatatypeConstants.FIELD_UNDEFINED);

		return xmlDate;
	}

	public static XMLGregorianCalendar toXMLGregorianCalendarWithoutZone(Date date) {
		XMLGregorianCalendar xmlGregorianCalendar = null;
		GregorianCalendar gregorianCalendar = new GregorianCalendar();
		gregorianCalendar.setTime(date);
		try {
			xmlGregorianCalendar = DatatypeFactory.newInstance().newXMLGregorianCalendar(gregorianCalendar);
			xmlGregorianCalendar.setTimezone(DatatypeConstants.FIELD_UNDEFINED);
		} catch (Exception e) {
			e.printStackTrace();
		}
		return xmlGregorianCalendar;
	}

	public static Date atEndOfDay(Date date) {
		LocalDateTime localDateTime = dateToLocalDateTime(date);
		LocalDateTime endOfDay = localDateTime.with(LocalTime.MAX);
		return localDateTimeToDate(endOfDay);
	}

	public static Date atStartOfDay(Date date) {
		LocalDateTime localDateTime = dateToLocalDateTime(date);
		LocalDateTime endOfDay = localDateTime.with(LocalTime.MIN);
		return localDateTimeToDate(endOfDay);
	}

	public static String atStartOfDayWithMilliseconds(Date date) {
		if (date == null) {
			return null;
		}
		LocalDate localDate = asLocalDateFromDate(date);
		SimpleDateFormat format = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.ss");
		DateTimeFormatter formatter = DateTimeFormatter.ofPattern(format.toPattern());
		return localDate.atStartOfDay().format(formatter);
	}

	public static String asSbmRequiredLocalDateTimeFromLocalDateTime(LocalDateTime date) {
		if (date == null) {
			return null;
		}
		SimpleDateFormat format = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.ss");
		DateTimeFormatter formatter = DateTimeFormatter.ofPattern(format.toPattern());
		return date.format(formatter);
	}

	public XMLGregorianCalendar fromLocalDateToXmlGregorianCalendar(LocalDate date) {
		XMLGregorianCalendar xmlGregorianCalendar = null;
		try {
			xmlGregorianCalendar = DatatypeFactory.newInstance().newXMLGregorianCalendar(date.toString());
		} catch (DatatypeConfigurationException e) {
			e.printStackTrace();
		}
		return xmlGregorianCalendar;
	}

	public XMLGregorianCalendar fromLocalDateTimeToXmlGregorianCalendar(LocalDateTime date) {
		XMLGregorianCalendar xmlGregorianCalendar = null;
		try {
			xmlGregorianCalendar = DatatypeFactory.newInstance().newXMLGregorianCalendar(date.toString());
		} catch (DatatypeConfigurationException e) {
			e.printStackTrace();
		}
		return xmlGregorianCalendar;
	}

	public XMLGregorianCalendar fromStringDateToXmlGregorianCalendar(String date) {
		XMLGregorianCalendar xmlGregorianCalendar = null;
		try {
			xmlGregorianCalendar = DatatypeFactory.newInstance().newXMLGregorianCalendar(date);
		} catch (DatatypeConfigurationException e) {
			e.printStackTrace();
		}
		return xmlGregorianCalendar;
	}

	public static Integer getAge(LocalDate birthDate) {
		return Period.between(birthDate, LocalDate.now()).getYears();
	}

	public static Integer getAge(Date date) {
		return getAge(asLocalDateFromDate(date));
	}

	public static LocalDateTime setHoursValue(LocalDate dateVal, int hour, int minute, int second, int milisecond) {
		return LocalDateTime.of(dateVal, LocalTime.of(hour, minute, second, milisecond));
	}

	public static Date localDateTimeToDate(LocalDateTime localDateTime) {
		return Date.from(localDateTime.atZone(ZoneId.systemDefault()).toInstant());
	}

	public static LocalDateTime dateToLocalDateTime(Date date) {
		return LocalDateTime.ofInstant(date.toInstant(), ZoneId.systemDefault());
	}

	public static Date convertStringToDateWithHourAndMinute(String str) {
		try {
			return new SimpleDateFormat("yyyy-MM-dd'T'HH:mm").parse(str);
		} catch (ParseException e) {
			logger.error("Parse Error convertStringToDateWithHourAndMinute : {}", e.getMessage());
		}
		return null;
	}

	public static String formatDate(String pattern, Date date) {

		if (date == null || !TStringUtil.hasText(pattern)) {
			return null;
		}
		SimpleDateFormat formatter = new SimpleDateFormat(pattern);
		return formatter.format(date);
	}

	public static Date toDateFromXMLGregorianCalendar(XMLGregorianCalendar calendar) {
		if (calendar == null) {
			return null;
		}
		return calendar.toGregorianCalendar().getTime();
	}

	public static Integer getYear(LocalDate date) {
		if (date == null) {
			return null;
		}
		String yearLong = date.format(DateTimeFormatter.ofPattern("yyyy"));
		return Integer.parseInt(yearLong);
	}

	public static Integer getYearShortFormat(LocalDate date) {
		if (date == null) {
			return null;
		}
		String yearShortFormat = date.format(DateTimeFormatter.ofPattern("yy"));
		return Integer.parseInt(yearShortFormat);
	}

	public static Date convertToDateFromString(String strDate) {
		DateFormat format1 = new SimpleDateFormat("dd-MM-yyyy");
		DateFormat format2 = new SimpleDateFormat("yyyy-MM-dd");
		try {
			return format2.parse(format2.format(format1.parse(strDate)));
		} catch (ParseException e) {
			logger.error("Parse Error convertToDateFromString : {}", e.getMessage());
		}
		return null;
	}

	public static Date convertToDateFromStringDDMMYYYY(String strDate) {
		DateFormat format = new SimpleDateFormat(DEFAULT_DATE);
		try {
			return format.parse(strDate);
		} catch (ParseException e) {
			logger.error("Parse Error convertToDateFromString : {}", e.getMessage());
		}
		throw new TOpenValidationException("Invalid date format");
	}

	public static Date convertYYYYMMDDFromDate(Date date) {
		SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd");
		try {
			return dateFormat.parse(dateFormat.format(date));
		} catch (ParseException e) {
			logger.error("Parse Error convertYYYYMMDDFromDate : {}", e.getMessage());
		}
		return null;
	}

	public static String convertYYYYMMDDHHmmssFromDate(Date date) {
		SimpleDateFormat dateFormat = new SimpleDateFormat("yyyyMMddHHmmss");
		return dateFormat.format(date);
	}


	public static String convertDDMMYYYYHHmmssFromDate(Date date) {
		SimpleDateFormat dateFormat = new SimpleDateFormat("ddMMyyyyHHmmss");
		return dateFormat.format(date);
	}

	public static Date convertDDMMYYYYHourFromDate(Date date) {
		SimpleDateFormat dateFormat = new SimpleDateFormat("ddMMyyyyHHmmss");
		try {
			return dateFormat.parse(dateFormat.format(date));
		} catch (ParseException e) {
			logger.error("Parse Error convertYYYYMMDDFromDate : {}", e.getMessage());
		}
		return null;
	}

	public static String convertYYYYMMDDFormatedFromDate(Date date) {
		SimpleDateFormat format = new SimpleDateFormat("yyyy-MM-dd");
		return format.format(date);
	}

	public static String convertDDMMYYYYFromDate(Date date) {
		SimpleDateFormat dateFormat = new SimpleDateFormat("dd-MM-yyyy");
		return dateFormat.format(date);
	}

	public static String convertYYYYMMddFromDate(Date date) {
		SimpleDateFormat dateFormat = new SimpleDateFormat("dd-MM-yyyy");
		return dateFormat.format(date);
	}

	public static Date asDateFromLocalDate(LocalDate localDate) {
		if (localDate == null) {
			return null;
		}
		return Date.from(localDate.atStartOfDay().atZone(ZoneId.systemDefault()).toInstant());
	}

	public static Date asDateFromLocalDateTime(LocalDateTime localDateTime) {
		if (localDateTime == null) {
			return null;
		}
		return Date.from(localDateTime.atZone(ZoneId.systemDefault()).toInstant());
	}

	public LocalDate fromXMLGregorianCalendarToLocalDate(XMLGregorianCalendar xmlCal) {
		LocalDate date = LocalDate.of(xmlCal.getYear(), xmlCal.getMonth(), xmlCal.getDay());
		return date;
	}

	public static LocalDate asLocalDateFromDate(Date date) {
		if (date == null) {
			return null;
		}
		return Instant.ofEpochMilli(date.getTime()).atZone(ZoneId.systemDefault()).toLocalDate();
	}

	public static Date getMaxDate(Date date1, Date date2) {
		if (date1 == null && date2 == null) {
			return null;
		} else if (date1 != null && date2 != null) {
			if (isFirstDateBeforeThanSecond(date1, date2)) {
				return date2;
			}
		}
		return date1 != null ? date1 : date2;
	}

	public static LocalDateTime asLocalDateTimeFromDate(Date date) {
		if (date == null) {
			return null;
		}
		return Instant.ofEpochMilli(date.getTime()).atZone(ZoneId.systemDefault()).toLocalDateTime();
	}

	public static boolean isFirstDateBeforeThanSecond(Date firstDate, Date secondDate) {
		if (firstDate == null || secondDate == null) {
			return false;
		}
		return firstDate.before(secondDate);
	}

	public static boolean isFirstDateBeforeThanSecond(LocalDate firstLocalDate, LocalDate secondLocalDate) {
		if (firstLocalDate == null || secondLocalDate == null) {
			return false;
		}
		return firstLocalDate.isBefore(secondLocalDate);
	}

	public static long getDayDifference(LocalDateTime firstDate, LocalDateTime secondDate) {
		if (firstDate == null || secondDate == null) {
			return 0L;
		}
		return ChronoUnit.DAYS.between(firstDate, secondDate);
	}

	public static long getDayDifferenceWithLocalDate(LocalDate firstDate, LocalDate secondDate) {
		if (firstDate == null || secondDate == null) {
			return 0L;
		}
		return ChronoUnit.DAYS.between(secondDate, firstDate);
	}

	public static LocalDate subtractDays(LocalDate date, int days) {
		return date.minusDays(days);
	}

	public static LocalDate addYearToLocalDate(LocalDate date, int years) {
		return date.plusYears(years);
	}

	public static Date addDateSeconds(Date date, Integer seconds) {
		Calendar calendar = Calendar.getInstance();
		calendar.setTime(date);
		calendar.add(Calendar.SECOND, seconds);
		return calendar.getTime();
	}

	public static Date addDateDays(Date date, Integer days) {
		Calendar calendar = Calendar.getInstance();
		calendar.setTime(date);
		calendar.add(Calendar.DATE, days);
		return calendar.getTime();
	}

	public static Date addDateMinutes(Date date, Integer minutes) {
		Calendar calendar = Calendar.getInstance();
		calendar.setTime(date);
		calendar.add(Calendar.MINUTE, minutes);
		return calendar.getTime();
	}

	public static LocalDate getLocalDateNow() {
		return LocalDate.now();
	}

	/**
	 * used to go back one month ago
	 *
	 * @param date LocalDate object
	 * @return LocalDate
	 */
	public static LocalDate getAMonthAgo(LocalDate date) {
		return date.minusMonths(1);
	}

	/**
	 * Converts month closing information to double digit format
	 *
	 * @param date LocalDate object
	 * @return String
	 */
	public static String getTechMonthClosingDoubleDigitFormat(LocalDate date) {
		String month = DECIMAL_FORMAT.format(Double.valueOf(date.getMonthValue()));
		return month;
	}

	/**
	 * Returns the year info from date
	 *
	 * @param date LocalDate object
	 * @return String
	 */
	public static String getYearFromLocalDate(LocalDate date) {
		return String.valueOf(date.getYear());
	}

	/**
	 * Returns localdate from string
	 *
	 * @param dateTxt LocalDate object
	 * @return String
	 */
	public static LocalDate getLocalDateFromString(DateTimeFormatter formatter, String dateTxt) {
		return LocalDate.parse(dateTxt, formatter);
	}

}
