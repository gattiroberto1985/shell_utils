#Spring Framework 

## Overview
Framework Java per lo sviluppo di applicazione Java Enterprise.
Alcuni vantaggi:

- Sviluppo di classi enterprise per mezzo di semplici classi POJO; non è più necessario la definizione di servlet con l'implementazione dei vari metodi (init, service, destroy, doRequest, ...)
- Modularità del framework;
    Fa uso di framework sottostanti consolidati (e. g. hibernate, log4j, ...);
- Facilitazione nello sviluppo dei test dell'applicazione;
- Contiene un framework MVC, che sostituisce bene i vari struts, ecc.;
- Mette a disposizione una serie di API utili per trasformare eccezioni "technology-specific" in eccezioni "generali";
- Mette a disposizione un transaction manager scalabile dalla singola connessione ad una infrastruttura di più ampio respiro (e. g. Java Transaction API);

### Dependency Injection ed Inversion of Control
Si tratta di un metodo per la gestione delle dipendenze tra le classi. Il caso standard è quello di una classe A dipendente da un'altra classe B: l'iniezione della dipendenza può avvenire sostanzialmente con due vie:

- passaggio al costruttore della classe A dei parametri relativi alla classe B;
- utilizzo, in fase di post-costruzione, dei metodi set.

Con *Inversion of Control* generalmente si intende un meccanismo che rimuova
la logica di generazione della dipendenza dalla classe padre, demandando
l'istanziazione ad un altro sistema.

###Aspect oriented programming

Strettamente correlato alla modularità, separa i vari "aspetti" dell'applicazione. Spring permette tale operazione dando la facoltà di definire metodi intercettori che disaccoppino classi che implementano funzioni distinte.

## Architettura del framework

Di seguito una illustrazione dell'architettura Spring:

![Architettura di Spring](./springfwk/01-architecture.jpg "Architettura di Spring")

[ ... ] Commenti generali sull'architettura del framework [ ... ]

## Inversion of control Containers
Il container Spring, cuore del framework, esegue la creazione degli oggetti, ne esegue il wire, li configura e ne gestisce l'intero lifecycle. Tale container utilizza la dependency injection per gestire le componenti dell'applicazione. Tali componenti (descritti in una serie di classi) sono detti SpringBeans.

Tutte le informazioni di cui necessita il container, vengono recuperate da una configurazione, che può essere costituita da una serie di annotation a livello di classe (più scanner configurato per eseguire lo scan di queste classi), da un file di configurazione XML o integralmente a livello di codice. Di seguito una immagine sul suo funzionamento:
Spring IoC Container

Spring mette a disposizione due tipi di container:

- `BeanFactory container`: fornisce un supporto di base per la DI ma è presente per sole questioni di retrocompatibilità; il suo utilizzo è consigliato solo per applicazioni molto leggere (e. g. mobile, applet, ecc.); un esempio in ( ... );

- `ApplicationContext container`: fornisce delle funzionalità più a livello enterprise. Contiene tutte le funzionalità del container al punto 1., pertanto è da considerarsi consigliato rispetto al precedente. Un esempio in (...).

## Spring Beans

Come anticipato, l'ossatura dell'applicazione è costituita dai beans Spring. Ogni bean deve essere configurato, e nello specifico il container deve conoscere:

- Come istanziare un bean;
- qual'è il suo lifecycle;
- quali sono le eventuali dipendenze.

Esistono a tal fine una serie di properties da impostare (XML, annotation, o hard-coded):

<table>
	<tr><th>Properties</th><th>Description</th></tr>
	<tr><td>class</td><td>This attribute is mandatory and specify the bean class to be used to create the bean</td></tr>
<tr><td>name</td><td>This attribute specifies the bean identifier uniquely. In XML-based configuration metadata, you use the id and/or name attributes to specify the bean identifier(s).</td></tr>
<tr><td>scope</td><td>This attribute specifies the scope of the objects created from a particular bean definition and it will be discussed in bean scopes chapter.
<tr><td>constructor-arg</td><td>This is used to inject the dependencies and will be discussed in next chapters.</td></tr>
<tr><td>properties</td><td>This is used to inject the dependencies and will be discussed in next chapters.</td></tr>
<tr><td>autowiring mode</td><td>This is used to inject the dependencies and will be discussed in next chapters.</td></tr>
<tr><td>lazy-initialization mode	</td><td>A lazy-initialized bean tells the IoC container to create a bean instance when it is first requested, rather than at startup.
<tr><td>initialization method</td><td>A callback to be called just after all necessary properties on the bean have been set by the container. It will be discussed in bean life cycle chapter.</td></tr>
<tr><td>destruction method</td><td>A callback to be used when the container containing the bean is destroyed. It will be discussed in bean life cycle chapter.</td></tr>

</table>
Un esempio/template di file di configurazione potrebbe essere il seguente:

    <?xml version="1.0" encoding="UTF-8"?>

    <beans xmlns="http://www.springframework.org/schema/beans"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation="http://www.springframework.org/schema/beans
        http://www.springframework.org/schema/beans/spring-beans-3.0.xsd">

       <!-- A simple bean definition -->
       <bean id="..." class="...">
           <!-- collaborators and configuration for this bean go here -->
       </bean>

	   <!-- A bean definition with lazy init set on -->
	   <bean id="..." class="..." lazy-init="true">
	       <!-- collaborators and configuration for this bean go here -->
	   </bean>
	
	   <!-- A bean definition with initialization method -->
	   <bean id="..." class="..." init-method="...">
	       <!-- collaborators and configuration for this bean go here -->
	   </bean>
	
	   <!-- A bean definition with destruction method -->
	   <bean id="..." class="..." destroy-method="...">
	       <!-- collaborators and configuration for this bean go here -->
	   </bean>
	
	   <!-- more bean definitions go here -->
	
	</beans>


## Scope dei beans

E' un attributo del tag precedente e i valori possibili sono i seguenti:

<table>
	<tr><th>Scope</th><th>Description</th></tr>
	<tr><td>singleton</td><td>This scopes the bean definition to a single instance per Spring IoC container (default).</td></tr>
	<tr><td>prototype</td><td>This scopes a single bean definition to have any number of object instances.</td></tr>
	<tr><td>request</td><td>This scopes a bean definition to an HTTP request. Only valid in the context of a web-aware Spring ApplicationContext.</td></tr>
	<tr><td>session</td><td>This scopes a bean definition to an HTTP session. Only valid in the context of a web-aware Spring ApplicationContext.</td></tr>
	<tr><td>global-session</td><td>This scopes a bean definition to a global HTTP session. Only valid in the context of a web-aware Spring ApplicationContext. </td></tr>
</table>

Gli ultimi tre saranno utili nel contesto web dello Spring ApplicationContext.

Per istanziare i bean è sufficiente una chiamata al metodo getBean del container:

      ApplicationContext context = new ClassPathXmlApplicationContext("Beans.xml");

      HelloWorld objA = (HelloWorld) context.getBean("helloWorld");

      objA.setMessage("I'm object A");
      objA.getMessage();


in Beans.xml è stata ovviamente definito un bean di nome "helloWorld", con riferimento alla classe opportuna. Tramite chiamate ai metodi set poi viene impostato il valore dei vari attributi.
Il lifecycle dei bean poi si implementa tramite alcune interfacce (e. g. InitializingBean e DisposableBean), di cui bisognerà definire alcuni metodi. A livello XML questo si traduce in una serie di attributi (e.g. init-method, destroy-method) che dovranno avere come valore un metodo residente nella classe che descrive il bean con una firma apposita.
E' anche possibile, nel caso i bean condividano i nomi dei metodi di init e destroy, definire dei default, nell'intestazione del file :

	<beans [ ... ]
	    default-init-method="init" 
	    default-destroy-method="destroy">


Per il corretto lifecycle inoltre, è opportuno chiamare anche il


	context.registerShutdownHook();


che assicura una uscita corretta chiamando tutti i metodi di distruzione.

## Bean PostProcessor

Definiscono delle callback da invocare in diverse fasi. Possono ad esempio personalizzare la fase di istanziazione, risoluzione dipendenze, pre/post metodi del lifecycle.
E' possibile definire più postprocessor, controllati tramite proprietà order..


## Ereditarietà nella definizione degli SpringBeans

E' possibile implementare il meccanismo dell'ereditarietà anche nella configurazione Spring dei vari Bean. A livello XML si ottiene tramite specifica dell'attributo parent:

	<?xml version="1.0" encoding="UTF-8"?>
	
	<beans xmlns="http://www.springframework.org/schema/beans"
	    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	    xsi:schemaLocation="http://www.springframework.org/schema/beans
	    http://www.springframework.org/schema/beans/spring-beans-3.0.xsd">
	
	   <bean id="helloWorld" class="com.tutorialspoint.HelloWorld">
	      <property name="message1" value="Hello World!"/>
	      <property name="message2" value="Hello Second World!"/>
	   </bean>
	
	   <bean id="helloIndia" class="com.tutorialspoint.HelloIndia" parent="helloWorld">
	      <property name="message1" value="Hello India!"/>
	      <property name="message3" value="Namaste India!"/>
	   </bean>
	
	</beans>

In aggiunta è anche possibile definire dei template (sempre nella configurazione), che non specificano alcuna classe ma che possono essere usati come parent dagli altri bean:

	<?xml version="1.0" encoding="UTF-8"?>
	
	<beans xmlns="http://www.springframework.org/schema/beans"
	    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	    xsi:schemaLocation="http://www.springframework.org/schema/beans
	    http://www.springframework.org/schema/beans/spring-beans-3.0.xsd">
	
	   <bean id="beanTeamplate" abstract="true">
	      <property name="message1" value="Hello World!"/>
	      <property name="message2" value="Hello Second World!"/>
	      <property name="message3" value="Namaste India!"/>
	   </bean>
	
	   <bean id="helloIndia" class="com.tutorialspoint.HelloIndia" parent="beanTeamplate">
	      <property name="message1" value="Hello India!"/>
	      <property name="message3" value="Namaste India!"/>
	   </bean>
	
	</beans>


## Dependency Injection ed IoC

Tipicamente in java si ha una dipendenza tra classi tramite classi "innestate" (da non confondere con le `nested class`, tutt'altra storia):

	public class TextEditor {
	   private SpellChecker spellChecker;
	   
	   public TextEditor() {
	      spellChecker = new SpellChecker();
	   }
	}

Nell'ottica dell'*inversion of control*, si otterrebbe invece qualcosa di diverso, dove la fase di costruzione dell'oggetto dipendenza è trasparente:

	public class TextEditor {
	   private SpellChecker spellChecker;
	   
	   public TextEditor(SpellChecker spellChecker) {
	      this.spellChecker = spellChecker;
	   }
	}

In questo caso è stata implementata una **iniezione per costruttore di
classe**, e per il corretto funzionamento il file di configurazione dei bean
dovrà contenere un parametro:


	<!-- Definition for textEditor bean -->
	<bean id="textEditor" class="com.tutorialspoint.TextEditor">
		<constructor-arg ref="spellChecker"/>
	</bean>

 Una via alternativa è quella di usare i metodi `set`.

In generale, è buona prassi utilizzare il metodo a costruttore per le 
dipendenze obbligatorie, tenendo quello coi metodi `set` per le dipendenze
opzionali.

## Iniezione di *inner bean*

Si tratta, come nel caso delle classi, di bean definiti nello scope di 
un altro bean:

	<bean id="outerBean" class="...">
		<property name="target">
        	<bean id="innerBean" class="..."/>
    	</property>
	</bean>

Può essere usato in entrambi i casi, sia come argomento di 
`<constructor-arg>` sia come `<property>`. Naturalmente l'`id` e il 
`target` vanno cablati di conseguenza con i nomi corretti.

## Iniezione di `Collection`

Spring permette la dependency injection anche su collection, come `set`,
`list`, `map` e `props` (sottocaso di `map`, con chiave e valore a `String`). 

Tipicamente si hanno due casi:

- Passaggio diretto dei valori della `Collection`:

		<!-- results in a setAddressList(java.util.List) call -->
		<bean id="addresses" class="my.Clazz">
		<property name="addressList">
			<list>
		    	<value>INDIA</value>
		    	<value>Pakistan</value>
		        <value>USA</value>
		        <value>USA</value>
		    </list>
		</property>

- Passaggio di un riferimento ad un oggetto della `Collection`.
	
		<bean id="addresses" class="my.Clazz">
		<!-- Passing bean reference  for java.util.List -->
		<property name="addressList">
		 <list>
		    <ref bean="address1"/>
		    <ref bean="address2"/>
		    <value>Pakistan</value>
		 </list>
		</property>

Deve naturalmente esistere una classe Java di nome `Clazz` nel 
package `my`, in cui è definito un membro `List addressList` con 
i relativi metodi `setAddressList` e `getAddressList`.

## AutoWiring dei beans

Consiste nell'identificazione automatica delle relazioni tra i vari bean
dell'applicazione ed aiuta a ridurre drasticamente il quantitativo di 
codice XML da scrivere.

Con riferimento alle due classi seguenti:

	package com.tutorialspoint;
	
	public class TextEditor {
	   private SpellChecker spellChecker;
	   private String name;
	
	   public void setSpellChecker( SpellChecker spellChecker ){
	      this.spellChecker = spellChecker;
	   }
	   public SpellChecker getSpellChecker() {
	      return spellChecker;
	   }
	
	   public void setName(String name) {
	      this.name = name;
	   }
	   public String getName() {
	      return name;
	   }
	
	   public void spellCheck() {
	      spellChecker.checkSpelling();
	   }
	}



	package com.tutorialspoint;
	
	public class SpellChecker {
	   public SpellChecker() {
	      System.out.println("Inside SpellChecker constructor." );
	   }
	
	   public void checkSpelling() {
	      System.out.println("Inside checkSpelling." );
	   }
	   
	}

ed al main:

	package com.tutorialspoint;
	
	import org.springframework.context.ApplicationContext;
	import org.springframework.context.support.ClassPathXmlApplicationContext;
	
	public class MainApp {
	   public static void main(String[] args) {
	      ApplicationContext context = 
	             new ClassPathXmlApplicationContext("Beans.xml");
	
	      TextEditor te = (TextEditor) context.getBean("textEditor");
	
	      te.spellCheck();
	   }
	}

segue una descrizione delle 4 modalità di autowire:

- `<novalue>`: nessun autowire, va tutto specificato a mano. Il file 
  `Beans.xml` dovrà contenere:

	   <!-- Definition for textEditor bean -->
	   <bean id="textEditor" class="com.tutorialspoint.TextEditor">
	      <property name="spellChecker" ref="spellChecker" />
	      <property name="name" value="Generic Text Editor" />
	   </bean>
	
	   <!-- Definition for spellChecker bean -->
	   <bean id="spellChecker" class="com.tutorialspoint.SpellChecker">

- `byName`: autowire ottenuto per matching del nome property. Il file 
  `Beans.xml` dovrà contenere:
		<!-- Definition for textEditor bean -->
		   <bean id="textEditor" class="com.tutorialspoint.TextEditor" 
		      autowire="byName">
		      <property name="name" value="Generic Text Editor" />
		   </bean>
		
		   <!-- Definition for spellChecker bean -->
		   <bean id="spellChecker" class="com.tutorialspoint.SpellChecker">
		   </bean>

   l'id del bean `spellChecker` coincide con il nome della property 
   relativa nella class `TextEditor`;

- `byType`: in base al tipo di `property`:

	   <!-- Definition for textEditor bean -->
	   <bean id="textEditor" class="com.tutorialspoint.TextEditor" 
	      autowire="byType">
	      <property name="name" value="Generic Text Editor" />
	   </bean>
	
	   <!-- Definition for spellChecker bean -->
	   <bean id="SpellChecker" class="com.tutorialspoint.SpellChecker">
	   </bean>

   Notare la `S` maiuscola nell'id del bean!

- `constructor`: come il `byType`, solo che si utilizza nel costruttore. In
   questo caso, `TextEditor` dovrà avere un costruttore con firma 
   `TextEditor( SpellChecker, String)`, e il file `Beans.xml` diventerà:

	   <!-- Definition for textEditor bean -->
	   <bean id="textEditor" class="com.tutorialspoint.TextEditor" 
	      autowire="constructor">
	      <constructor-arg value="Generic Text Editor"/>
	   </bean>
	
	   <!-- Definition for spellChecker bean -->
	   <bean id="SpellChecker" class="com.tutorialspoint.SpellChecker">
	   </bean>

- `autodetect`: modalità "automatica", in cui Spring tenta la modalità
   `constructor` e nel caso di insuccesso la `byType`.

Il `byType` e il `constructor` si possono utilizzare per gli array e in 
generale per le collection.

### Limitazioni dell'`autowire`

- Genera confusione se è usato "a sprazzi"; se si usa, meglio farlo in 
  tutto il progetto;
- E' comunque possibile usare i `constructor-arg` e le `property`, 
  bypassando quanto stabilito dall'autowire;
- Non è possibile eseguire l'autowire di tipi primitivi (vedi la stringa
  nell'esempio precedente);
- E' meno esplicito del wiring esplicito.

## Configurazione via annotations

E' possibile eseguire la configurazione via annotation, ma è da tenere in
considerazione che in caso di presenza di configurazione XML quest'ultima
ha la meglio (XML mangia annotation).

Di default è disabilitata, e per attivarla bisogna indicarlo. Ad esempio,
nel caso di un context definito via XML si dovrà avere:


	<!-- Definition for textEditor bean -->
	<bean id="textEditor" class="com.tutorialspoint.TextEditor" 
		autowire="constructor">
		<constructor-arg value="Generic Text Editor"/>
	</bean>
	
	<!-- Definition for spellChecker bean -->
	<bean id="SpellChecker" class="com.tutorialspoint.SpellChecker">
	</bean>

Alcune annotation sono le seguenti:

- `@Required`: si applica ai `setters` e indica che la property del bean
   deve essere popolata nel file di configurazione XML;

- `@Autowired`: applicata ai metodi `setters`, indica che per la property
   dovrà essere eseguito l'autowire. Ad esempio:

	   @Autowired
	   public void setSpellChecker( SpellChecker spellChecker ){
	      this.spellChecker = spellChecker;
	   }

   e nel `Beans.xml`:

	   <!-- Definition for textEditor bean without constructor-arg  -->
	   <bean id="textEditor" class="com.tutorialspoint.TextEditor">
	   </bean>
	
	   <!-- Definition for spellChecker bean -->
	   <bean id="spellChecker" class="com.tutorialspoint.SpellChecker">
	   </bean>

   Si può applicare anche alle properties, con il medesimo funzionamento
   di cui sopra.
   Infine, è applicabile anche sui costruttori (sempre uguale a prima).
   Si può rilassare la condizione di require, impostando l'attributo a 
   false:
     
		@Autowired ( required = false )


# Spring MVC

Permette l'utilizzo del pattern MVC in ambiente Spring. Le tre componenti
classiche del pattern sono:

- `Model`: rappresentati dalle classi che rappresentano gli oggetti gestiti e 
  le classi di accesso al db;
- `View`: rappresentate dai file `jsp`;
- `Controller`: classi che rimangono in ascolto su un `URL` e si occupa di 
  gestire la richiesta dell'utente.

Alcuni vantaggi dichiarati:

- è adattabile, flessibile e non intrusivo grazie alla presenza delle annotations;
- permette di scrivere codice riusabile;
- possibilità di essere esteso tramite adattatori e validatori scritti ad hoc per 
  le nostre esigenze;
- url dinamici, SEO-friendly e personalizzabili;
- gestione integrata dell’internazionalizzazione e dei temi;
- libreria JSP sviluppata ad hoc per facilitare alcune operazioni ripetitive;
- nuovi scope per i bean (request e session) che permettono di adattare i container 
  base di Spring anche al mondo web.

## Configurazione 

Tutto ruota intorno ad una servlet, `DispatcherServlet`, che dovrà gestire tutte 
le chiamate del caso. Nel `web.xml` dovrà quindi esser inserito il seguente corpo:

	<servlet>
	    <servlet-name>springmvc</servlet-name>
	    <servlet-class>org.springframework.web.servlet.DispatcherServlet</servlet-class>
    	<load-on-startup>1</load-on-startup>
	</servlet>
	<servlet-mapping>
	    <servlet-name>springmvc</servlet-name>
    	<url-pattern>/</url-pattern>
	</servlet-mapping>

Dove in `url-pattern` si può restringere l'ambito di intervento. Qui è stato impostato 
il path di root, pertanto tutte le richieste saranno dirottate verso spring.
All'avvio, viene ricercato nella `WEB-INF` un file con il nome specificato nel 
`servlet-name` seguito da `-servlet.xml`, con una struttura simile a quella del file
`beans.xml` in spring core:

	<beans	
		xmlns="http://www.springframework.org/schema/beans"
		xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       	xsi:schemaLocation="http://www.springframework.org/schema/beans 
		http://www.springframework.org/schema/beans/spring-beans-3.0.xsd">
		
	</beans>

Spring MVC si basa sul modello _*convention over configuration*_, cioè pochi magheggi e intenso
utilizzo delle convenzioni; tuttavia è possibile personalizzare ulteriormente la struttura
definita sopra nella definizione della servlet.

### `WebApplicationContext`
Per ciascuna servlet viene istanziato un oggetto di tipo `WebApplicationContext`, all'interno del
quale vivono tutti i bean necessari alla servlet stessa. Questo contesto viene poi agganciato
al contesto standard `ServletContext`, in modo da essere facilmente recuperabile. 
I principali bean contenuti nel contesto web sono: 

<table>
	<tr><th>Bean</th><th>Descrizione</th></tr>
	<tr><td>HandlerMapping</td><td>Bean che si occupa di mappare le url invocate dal client verso un particolare metodo o classe; il bean di default utilizza le java annotations</td></tr>
	<tr><td>HandlerExceptionResolver</td><td>Bean che gestisce l’output al client in caso di eccezioni</td></tr>
	<tr><td>ViewResolver</td><td>Bean che si occupa di identificare quale view caricare sulla base del nome in formato stringa</td></tr>
	<tr><td>LocaleResolver</td><td>Bean che gestisce l’internazionalizzazione</td></tr>
</table>

Per sovrascrivere questi bean basta includere nel contesto un nuovo bean dello stesso tipo 
che punti ad una classe esterna.

## Spring MVC 

### Controllers
Costituiscono i componenti invocati direttamente dal client, che si occupano delle principali
logiche di business e che possono esistere anche senza la presenza di `Model` e `View`.

Il Bean che si occupa del mapping tra url e metodo da invocare è il primo nella tabella precedente,
e l'implementazione di default è il `RequestMappingHandlerMapping`. Fa uso delle due annotations
`@controller`, a livello di classe e che specifica che si tratta di un controller, e di 
`requestMapping` a livello di metodo che accetta come parametro l'url da mappare:

	package it.test;

	@Controller
	public class DemoController
	{
    	@RequestMapping(value="/home")    	 
    	public String getIndex() 
    	{
    	    return "index";
    	}
	}

Per il corretto funzionamento del tutto bisogna specificare il punto da cui partire per 
ricercare gli oggetti spring:

	<context:component-scan base-package="it.test"/>

da inserire nel `WebApplicationContext`.

#### `@RequestMapping` e parametri con `@RequestParam`

L'url da gestire è personalizzabile:

	@RequestMapping(value="/book/{idBook}", method=RequestMethod.GET)
	public void getBook(@PathVariable("idBook") int id) 
	{
    	// [...]
	}

	@RequestMapping(value="/book", method=RequestMethod.GET)
	public void getBookByParam(@RequestParam("bookId") int id)
	{
		// Se per esempio ho chiamato /book specificando dati... Ad esempio, per
		//
		// http://localhost:8080/MyApp/user/1234/invoices?date=12-05-2013
		//
		// avrei un qualcosa del tipo @PathVariable("userid") che mappa 1234
		// e @RequestParam(value = "date", required = false) per la data (dopo ?)
    	System.out.println("Requested book " + id);
	}

Il valore di ritorno, tipicamente una stringa, identifica la view da utilizzare, che deve
essere gestita a livello di view resolver.

<!--

##### Info di servizio: differenze RequestParam e PathVariable


    @PathVariable is to obtain some placeholder from the uri (Spring call it an URI Template) — see Spring Reference Chapter 16.3.2.2 URI Template Patterns
    @RequestParam is to obtain an parameter — see Spring Reference Chapter 16.3.3.3 Binding request parameters to method parameters with @RequestParam

If URL http://localhost:8080/MyApp/user/1234/invoices?date=12-05-2013 gets the invoices for user 1234 on December 5th, 2013, the controller method would look like:

@RequestMapping(value="/user/{userId}/invoices", method = RequestMethod.GET)
public List<Invoice> listUsersInvoices(
            @PathVariable("userId") int user,
            @RequestParam(value = "date", required = false) Date dateOrNull) {
  ...
}

Also, request parameters can be optional, but path variables cannot--if they were, it would change the URL path hierarchy and introduce request mapping conflicts. For example, would /user/invoices provide the invoices for user null or details about a user with ID "invoices"?

-->

#### Signature dei metodi handler

In generale i metodi sono personalizzabili a piacere. Un elenco completo è 
il seguente:

- Parametri annotati con @PathVariable recuperati dal pattern.
- Parametri annotati con @RequestParam ed inviati via HTTP dal client.
- HttpServletRequest e HttpServletResponse (e anche ServletRequest e ServletResponse) per accedere direttamente agli oggetti nativi J2EE.
- HttpSession per sfruttare la sessione senza doverla recuperare manualmente dalla request.
- Locale per identificare automaticamente il locale utilizzato.
- InputStream e OutputStream per lavorare a basso livello direttamente sugli stream in ingresso e in uscita.
- Parametri annotati con @RequestHeader per avere un determinato valore tra gli header HTTP ricevuti.
- Parametri annotati con @RequestBody per avere direttamente il corpo della request.
- Map (o Model) per passare alla view valori dinamici.
- Errors (o BindingResult) per gestire la validazione dei form.

Ad esempio sono ammessi:

	public void withSession(HttpSession session) {
    	// TODO...
	}

	public void withResponseRequest(HttpServletRequest request, HttpServletResponse response) {
    	// TODO...
	}

	public void withLocale(Locale locale) {
    	// TODO...
	}

#### Valori di ritorno dei metodi handler

Di seguito un elenco dei possibili valori di ritorno dei metodi handler:

- void per comunicare a Spring MVC che l’intera gestione del flusso di response verrà gestita manualmente;
- una stringa per invocare un ViewResolver che a partire da essa recupererà una particolare vista (JSP per esempio) da utilizzare;
- una stringa con prefisso redirect: per forzare una redirect verso un’altra url;
- una stringa con prefisso forward: per forzare il forward verso un altro handler;
- un ModelAndView (o un Model) che incapsulano sia il nome della vista da caricare sia l’insieme dei dati da passare ad essa;
- qualsiasi tipo di oggetto da convertire tramite un HttpMessageConverter (per esempio in JSON o XML) se il metodo è annotato con @ResponseBody.


## View resolver

Vengono utilizzati quando il controller ritorna una stringa o un oggetto `ModelAndView`.
Il caso standard è quello con l'utilizzo dell'`InternalResourceViewResolver`, che può essere creato
tramite specifica nel contesto:

	<bean id="viewResolver" class="org.springframework.web.servlet.view.UrlBasedViewResolver">
		<property name="viewClass" value="org.springframework.web.servlet.view.JstlView"/>
		<property name="prefix" value="/WEB-INF/view/"/>
		<property name="suffix" value=".jsp"/>
	</bean>

queste direttive indicano che la stringa ritornata dal metodo dovrà essere concatenata a `WEB-INF/view`
come prefisso e `.jsp` come suffisso. Inoltre, se nel corpo del metodo viene istanziato o modificato
un oggetto `Model` o `ModelAndView`, questo verrà passato alla view:

	@RequestMapping(value="/pagina-personale", method=RequestMethod.GET)
	    public String paginaPersonale(Model model) {
    	model.addAttribute("nome", "Alberto");
    	model.addAttribute("cognome", "Bottarini");
    	return "pagina-personale";
	}

i parametri poi sono referenziabili in maniera standard (`${nome}` ecc).

### Altri resolver

Di seguito una lista di altri resolver utilizzabili:

<table>
	<tr><th>Resolver</th><th>Descrizione</th></tr>
	<tr><td>XmlViewResolver</td><td>Identifica la view corretta a partire da un file XML di configurazione.</td></tr>
	<tr><td>ResourceBoundleViewResolver</td><td>Identifica la view corretta a partire da chiavi contenuto nel resource boundle (utile per offrire viste localizzate).</td></tr>
	<tr><td>UrlBasedViewResolver</td><td>Identifica la view corretta trasformando il nome logico della vista in un URL (l’InternalResourceViewResolver è una sottoclasse di UrlBasedViewResolver).</td></tr>
	<tr><td>ContentNavigationViewResolver</td><td>Identifica la view sulla base del filename richiesto o in base al parametro Accept della request.</td></tr>
	<tr><td>BeanNameViewResolver</td><td>Identifica la view sulla base del nome del bean all’interno del contesto di Spring MVC.</td></tr>
</table>


## Form