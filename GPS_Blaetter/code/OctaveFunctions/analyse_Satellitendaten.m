function [SK, dS, SP, GK] = analyse_Satellitendaten(tE, tS, Ephemeriden)
% Satellitenkoordinaten
SK = berechne_Satellitenkoordinaten(tS,Ephemeriden);
% Pseudoentfernungen
c = 299792458;% Ausbreitungsgeschwindigkeit der Nachrichten in m/s
dS =(tE-tS) * c;% Ersetze NaN durch eine Formel in tS, tE und c, welche die Pseudoentfernungen berechnet
% Empfaengerposition
SP = trilaterate(SK(:,1),SK(:,2),SK(:,3),dS(1),dS(2),dS(3));
% Geografische Koordinaten
h =  sqrt(SP(1)^2+SP(2)^2+SP(3)^2)-6378137.0;% Ersetze NaN durch eine Formal, mit der sich die Höhe h berechnen lässt
phi = atan(SP(3)/sqrt(SP(1)^2+SP(2)^2))*180/pi;% Ersetze NaN durch eine Formal, mit der sich geografische Breite berechnen lässt
lambda =  atan2(SP(2),SP(1))*180/pi;% Ersetze NaN durch eine Formal, mit der sich die geografische Länge berechnen lässt
GK = [h phi lambda];
endfunction

function SK = berechne_Satellitenkoordinaten(t,Ephemeriden)
%BERECHNE_SATELLITENKOORDINATEN berechnet X,Y,Z ECEF Koordinaten
%   Eingabe:
%       - t = Vektor der Zeitpunkte in Sekunden
%       - Ephemeriden = Ephemeridenmatrix
%   Ausgabe:
%       - x,y,z = Koordinaten der Satelliten in Meter
%   Aufruf:
%       [x,y,z] = berechne_Satellitenkoordinaten(t,Ephemeriden)

% Lese Ephemeriden
M0       = Ephemeriden(1,:);
deltan   = Ephemeriden(2,:);
ecc      = Ephemeriden(3,:);
rootA    = Ephemeriden(4,:);
Omega0   = Ephemeriden(5,:);
i0       = Ephemeriden(6,:);
omega    = Ephemeriden(7,:);
Omegadot = Ephemeriden(8,:);
idot     = Ephemeriden(9,:);
cuc      = Ephemeriden(10,:);
cus      = Ephemeriden(11,:);
crc      = Ephemeriden(12,:);
crs      = Ephemeriden(13,:);
cic      = Ephemeriden(14,:);
cis      = Ephemeriden(15,:);
toe      = Ephemeriden(16,:);

% Vorschrift zur Berechnung der Satellitenkoordinaten
mu = 3.986005e14;
Omegae_dot = 7.2921151467e-5;
A = rootA.*rootA;
n0 = sqrt(mu./A.^3);
tk = t-toe;
n = n0+deltan;
M = M0+n.*tk;
E = M;
for i = 1:20
   E_old = E;
   E = M+ecc.*sin(E);
   dE = E-E_old;
   if max(abs(dE)) < 1.e-12
      break;
   end
end
v = atan2(sqrt(1-ecc.^2).*sin(E), cos(E)-ecc);
phi = v+omega;
u = phi                + cuc.*cos(2*phi)+cus.*sin(2*phi);
r = A.*(1-ecc.*cos(E)) + crc.*cos(2*phi)+crs.*sin(2*phi);
i = i0+idot.*tk        + cic.*cos(2*phi)+cis.*sin(2*phi);
Omega = Omega0+(Omegadot-Omegae_dot).*tk-Omegae_dot*toe;
x1 = cos(u).*r;
y1 = sin(u).*r;
x = x1.*cos(Omega)-y1.*cos(i).*sin(Omega);
y = x1.*sin(Omega)+y1.*cos(i).*cos(Omega);
z = y1.*sin(i);
SK = [x; y; z];
end

function SP=trilaterate(P1,P2,P3,r1,r2,r3)
temp1 = P2-P1;
e_x = temp1/norm(temp1);
temp2 = P3-P1;
i = dot(e_x,temp2);
temp3 = temp2 - i*e_x;
e_y = temp3/norm(temp3);
e_z = cross(e_x,e_y);
d = norm(P2-P1);
j = dot(e_y,temp2);
x = (r1*r1 - r2*r2 + d*d) / (2*d);               
y = (r1*r1 - r3*r3 -2*i*x + i*i + j*j) / (2*j);
temp4 = r1*r1 - x*x - y*y;                            
if temp4<0
    printf('%s\n','Die drei Kugeln schneiden sich nicht!')
else
    z = sqrt(temp4);
    SP1 = P1 + x*e_x + y*e_y + z*e_z;                  
    SP2 = P1 + x*e_x + y*e_y - z*e_z;
    aequatorradius = 6378137.0;
    if abs(norm(SP1)-aequatorradius) < abs(norm(SP2)-aequatorradius)
        SP = SP1;
    else
        SP = SP2;
    end
end
endfunction